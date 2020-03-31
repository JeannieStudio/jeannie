#!/usr/bin/env bash
RED_COLOR="\033[0;31m"
NO_COLOR="\033[0m"
GREEN="\033[0;32m"
echo "export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin:$PATH" >> ~/.bashrc
source ~/.bashrc
echo "等3秒……"
sleep 3
mkdir /etc/caddy /etc/ssl/caddy /var/www
isRoot(){
  if [[ "$EUID" -ne 0 ]]; then
    echo "false"
  else
    echo "true"
  fi
}
init_release(){
  if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
    fi
  if [[ $release = "ubuntu" || $release = "debian" ]]; then
    PM='apt'
  elif [[ $release = "centos" ]]; then
    PM='yum'
  else
    exit 1
  fi
  # PM='apt'
}
caddy_install(){
  curl https://getcaddy.com | bash -s personal hook.service
}
caddy_conf(){
  read -p "输入您的域名:" domainname
  read -p "您输入的域名正确吗? [y/n]?" answer
  if [ $answer != "y" ]; then
     read -p "请重新输入您的域名:" domainname
  fi
  read -p "请输入您的邮箱：" emailname
  read -p "您输入的邮箱正确吗? [y/n]?" answer
  if [ $answer != "y" ]; then
     read -p "请重新输入您的邮箱：" emailname
  fi
  echo "http://${domainname}:80 {
        redir https://${domainname}:1234{url}
       }
        https://${domainname}:1234 {
        gzip
        timeouts none
        tls ${emailname}
        root /var/www
        proxy / 127.0.0.1:5678
       }" > /etc/caddy/Caddyfile
}
ssr_install(){
   wget --no-check-certificate -O shadowsocks-all.sh https://raw.githubusercontent.com/teddysun/shadowsocks_install/master/shadowsocks-all.sh
   chmod +x shadowsocks-all.sh
   ./shadowsocks-all.sh 2>&1 | tee shadowsocks-all.log
    #分别将配置/etc/shadowsocks-r/config.json文件的第4行和第14行改为下面内容
    sed -i '4c "server_port":443,' /etc/shadowsocks-r/config.json
    sed -i "14c \"redirect\": [\"*:443#127.0.0.1:1234\"]," /etc/shadowsocks-r/config.json
}
filebrowser_install(){
    systemctl stop filebrowser.service
    curl -fsSL https://filebrowser.xyz/get.sh | bash
    filebrowser -d /etc/filebrowser.db config init
    filebrowser -d /etc/filebrowser.db config set --address 0.0.0.0
    filebrowser -d /etc/filebrowser.db config set --port 5678
    filebrowser -d /etc/filebrowser.db config set --locale zh-cn
    filebrowser -d /etc/filebrowser.db config set --log /var/log/filebrowser.log
    read -p  "输入个人在线私有云盘用户名:" user
    read -p  "输入个人在线私有云盘密码:" pswd
    filebrowser -d /etc/filebrowser.db users add $user $pswd --perm.admin
    echo "[Unit]
    Description=File Browser
    After=network.target
    [Service]
    ExecStart=/usr/local/bin/filebrowser -d /etc/filebrowser.db
    [Install]
    WantedBy=multi-user.target" > /lib/systemd/system/filebrowser.service
}
main(){
   isRoot=$( isRoot )
  if [[ "${isRoot}" != "true" ]]; then
    echo -e "${RED_COLOR}error:${NO_COLOR}Please run this script as as root"
    exit 1
  else
  caddy_install
  caddy_conf
  ssr_install
  filebrowser_install
  caddy -service stop
  caddy -service uninstall
  caddy -service install -agree -email ${emailname} -conf /etc/caddy/Caddyfile
  caddy -service start
  /etc/init.d/shadowsocks-r restart
  caddy -service restart
  systemctl start filebrowser.service
  systemctl enable filebrowser.service
  pwd=$(sed -n '7p' /etc/shadowsocks-r/config.json)
  method=$(sed -n '9p' /etc/shadowsocks-r/config.json)
  Protocol=$(sed -n '10p' /etc/shadowsocks-r/config.json)
  obfs=$(sed -n '12p' /etc/shadowsocks-r/config.json)
  echo -e "${GREEN}恭喜你，安装和配置成功
域名:        ${GREEN}\"${domainname}\"
端口:        ${GREEN}\"443\"
密码:        ${GREEN}${pwd##*:}
密码方式:    ${GREEN}${method##*:}
协议:        ${GREEN}${Protocol##*:}
混淆:        ${GREEN}${obfs##*:}
访问：${GREEN}https://${domainname}  体验个人在线私有云盘.
登录名：$user ，密码：$pswd。" 2>&1 | tee info
  touch /etc/motd
  cat info > /etc/motd
  fi
}
main
