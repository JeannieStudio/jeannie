#!/bin/bash
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
 v2ray_install(){
   cp  /usr/share/zoneinfo/Asia/Shanghai  /etc/localtime
   service v2ray stop
   bash <(curl -L -s https://install.direct/go.sh)
 }
 caddy_install(){
   PID=$(ps -ef |grep "caddy" |grep -v "grep" |grep -v "init.d" |grep -v "service" |grep -v "caddy_install" |awk '{print $2}')
	[[ ! -z ${PID} ]] && kill -9 ${PID}
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
        redir https://${domainname}:443{url}
       }
        https://${domainname}:443 {
        gzip
        timeouts none
        tls ${emailname}
        root /var/www
        proxy / 127.0.0.1:5678 {
          except /ray
        }
        proxy /ray 127.0.0.1:10000 {
           websocket
           header_upstream -Origin
        }
       }" > /etc/caddy/Caddyfile
}
genId(){
    id1=$(cat /proc/sys/kernel/random/uuid | md5sum |cut -c 1-8)
    id2=$(cat /proc/sys/kernel/random/uuid | md5sum |cut -c 1-4)
    id3=$(cat /proc/sys/kernel/random/uuid | md5sum |cut -c 1-4)
    id4=$(cat /proc/sys/kernel/random/uuid | md5sum |cut -c 1-4)
    id5=$(cat /proc/sys/kernel/random/uuid | md5sum |cut -c 1-12)
    id=$id1'-'$id2'-'$id3'-'$id4'-'$id5
    echo "$id"
}
v2ray_conf(){
  genId
  read -p  "已帮您随机产生一个uuid:
  $id，
  满意吗？（输入y表示不满意再生成一个，按其他键表示接受）" answer
  while [ $answer = "y" ]; do
      genId
      read -p  "uuid:$id，满意吗？（不满意输入y,按其他键表示接受）" answer
  done
  rm -f config.json
  curl -O https://raw.githubusercontent.com/JeannieStudio/jeannie/master/config.json
  sed -i "s/"b831381d-6324-4d53-ad4f-8cda48b30811"/$id/g" config.json
  cp -f config.json /etc/v2ray/config.json
}
filebrowser_install(){
    systemctl stop filebrowser.service
    rm  -f /etc/filebrowser.db
    curl -fsSL https://filebrowser.xyz/get.sh | bash
    filebrowser -d /etc/filebrowser.db config init
    filebrowser -d /etc/filebrowser.db config set --address 0.0.0.0
    filebrowser -d /etc/filebrowser.db config set --port 5678
    filebrowser -d /etc/filebrowser.db config set --locale zh-cn
    filebrowser -d /etc/filebrowser.db config set --log /var/log/filebrowser.log
    read -p "输入个人在线私有云盘用户名:" user
    read -p "输入个人在线私有云盘密码:" pswd
    filebrowser -d /etc/filebrowser.db users add ${user} ${pswd} --perm.admin
    echo "[Unit]
    Description=File Browser
    After=network.target
    [Service]
    ExecStart=/usr/local/bin/filebrowser -d /etc/filebrowser.db
    [Install]
    WantedBy=multi-user.target" > /lib/systemd/system/filebrowser.service
}
wget_install(){
  init_release
  if [[ ${PM} = "apt" ]]; then
    apt-get install wget
  elif [[ ${PM} = "yum" ]]; then
    yum -y install wget
  fi
}
main(){
   isRoot=$( isRoot )
  if [[ "${isRoot}" != "true" ]]; then
    echo -e "${RED_COLOR}error:${NO_COLOR}Please run this script as as root"
    exit 1
  else
  wget_install
  caddy_install
  caddy_conf
  v2ray_install
  v2ray_conf
  filebrowser_install
  service v2ray start
  caddy -service stop
  caddy -service uninstall
  caddy -service install -agree -email ${emailname} -conf /etc/caddy/Caddyfile
  caddy -service start
  caddy -service restart
  systemctl start filebrowser.service
  systemctl enable filebrowser.service
  echo -e "${GREEN}恭喜你，v2ray安装和配置成功
域名:        ${GREEN}${domainname}
端口:        ${GREEN}443
UUID:        ${GREEN}${id}
混淆:        ${GREEN}websocket
路径：       ${GREEN}/ray
访问：${GREEN}https://${domainname}  体验个人在线私有云盘.
登录名：$user ，密码：$pswd。" 2>&1 | tee info
  touch /etc/motd
  cat info > /etc/motd
  fi
}
main
