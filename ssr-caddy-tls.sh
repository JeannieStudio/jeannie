#!/usr/bin/env bash
# Author: Jeannie
#######color code########
RED_COLOR="\033[0;31m"
NO_COLOR="\033[0m"
GREEN="\033[32m\033[01m"
BLUE="\033[0;36m"
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
tools_install(){
  PID=$(ps -ef | grep "v2ray" | grep -v grep | awk '{print $2}')
  [[ ! -z ${PID} ]] && kill -9 ${PID}
  PID=$(ps -ef | grep "trojan" | grep -v grep | awk '{print $2}')
  [[ ! -z ${PID} ]] && kill -9 ${PID}
  PID=$(ps -ef | grep "nginx" | grep -v grep | awk '{print $2}')
  [[ ! -z ${PID} ]] && kill -9 ${PID}
  PID=$(ps -ef | grep "caddy" | grep -v grep | awk '{print $2}')
	[[ ! -z ${PID} ]] && kill -9 ${PID}
  init_release
  if [ $PM = 'apt' ] ; then
    apt-get update -y
    apt-get install -y dnsutils wget unzip zip curl tar git
  elif [ $PM = 'yum' ]; then
    yum update -y
    yum -y install bind-utils wget unzip zip curl tar git
  fi
}
left_second(){
    seconds_left=30
    while [ $seconds_left -gt 0 ];do
      echo -n $seconds_left
      sleep 1
      seconds_left=$(($seconds_left - 1))
      echo -ne "\r     \r"
    done
}
caddy_install(){
  curl https://getcaddy.com | bash -s personal hook.service
}
caddy_conf(){
  read -p "输入您的域名:" domainname
  real_addr=`ping ${domainname} -c 1 | sed '1{s/[^(]*(//;s/).*//;q}'`
  local_addr=`curl ipv4.icanhazip.com`
  while [ "$real_addr" != "$local_addr" ]; do
     read -p "本机ip和绑定域名的IP不一致，请检查域名是否解析成功,并重新输入域名:" domainname
     real_addr=`ping ${domainname} -c 1 | sed '1{s/[^(]*(//;s/).*//;q}'`
     local_addr=`curl ipv4.icanhazip.com`
  done
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
       }" > /etc/caddy/Caddyfile
}
ssr_install(){
  /etc/init.d/shadowsocks-r stop
   wget --no-check-certificate -O shadowsocks-all.sh https://raw.githubusercontent.com/teddysun/shadowsocks_install/master/shadowsocks-all.sh
   chmod +x shadowsocks-all.sh
   ./shadowsocks-all.sh 2>&1 | tee shadowsocks-all.log
    #分别将配置/etc/shadowsocks-r/config.json文件的第4行和第14行改为下面内容
    sed -i '4c "server_port":443,' /etc/shadowsocks-r/config.json
    sed -i "14c \"redirect\": [\"*:443#127.0.0.1:1234\"]," /etc/shadowsocks-r/config.json
}
web_get(){
  rm -rf /var/www
  mkdir /var/www
  git clone https://github.com/JeannieStudio/Programming.git /var/www
}
check_CA(){
    end_time=$(echo | openssl s_client -servername $domainname -connect $domainname:443 2>/dev/null | openssl x509 -noout -dates |grep 'After'| awk -F '=' '{print $2}'| awk -F ' +' '{print $1,$2,$4 }' )
    end_times=$(date +%s -d "$end_time")
    now_time=$(date +%s -d "$(date | awk -F ' +'  '{print $2,$3,$6}')")
    RST=$(($(($end_times-$now_time))/(60*60*24)))
}
CA_exist(){
  if [ -d "/root/.caddy/acme/acme-v02.api.letsencrypt.org/sites/$domainname" -o -d "/.caddy/acme/acme-v02.api.letsencrypt.org/sites/$domainname" ]; then
    FLAG="YES"
  else
    FLAG="NO"
  fi
}
main(){
   isRoot=$( isRoot )
  if [[ "${isRoot}" != "true" ]]; then
    echo -e "${RED_COLOR}error:${NO_COLOR}Please run this script as as root"
    exit 1
  else
  tools_install
  web_get
  caddy_install
  caddy_conf
  ssr_install
  caddy -service stop
  caddy -service uninstall
  caddy -service install -agree -email ${emailname} -conf /etc/caddy/Caddyfile
  caddy -service start
  echo "睡一会儿……"
  left_second
  caddy -service start
  /etc/init.d/shadowsocks-r restart
  caddy -service restart
  pwd=$(sed -n '7p' /etc/shadowsocks-r/config.json)
  method=$(sed -n '9p' /etc/shadowsocks-r/config.json)
  Protocol=$(sed -n '10p' /etc/shadowsocks-r/config.json)
  obfs=$(sed -n '12p' /etc/shadowsocks-r/config.json)
  check_CA
  CA_exist
  if [ $FLAG = "YES" ]; then
  echo -e "
${GREEN} ===================================================
${GREEN}       恭喜你，Trojan安装和配置成功
${GREEN} ===================================================
${BLUE}域名:        ${GREEN}\"${domainname}\"
${BLUE}端口:        ${GREEN}\"443\"
${BLUE}密码:        ${GREEN}${pwd##*:}
${BLUE}加密方式:    ${GREEN}${method##*:}
${BLUE}协议:        ${GREEN}${Protocol##*:}
${BLUE}混淆:        ${GREEN}${obfs##*:}
${BLUE}访问：${GREEN}https://${domainname}  体验个人在线私有云盘.
${BLUE}登录名：$user ，密码：$pswd。
${GREEN}=========================================================
${BLUE} Windows客户端请从这里下载： $GREEN  https://github.com/shadowsocksrr/shadowsocksr-csharp/releases
${BLUE} macOS客户端请从这里下载: $GREEN https://github.com/qinyuhang/ShadowsocksX-NG-R/releases
$BLUE ios客户端到应用商店下载：$GREEN shadowrocket;
$BLUE 安卓请客户端下载：$GREEN https://github.com/shadowsocksrr/shadowsocksr-android/releases
$BLUE 关注jeannie studio：$GREEN https://bit.ly/2X042ea
${GREEN}=========================================================
${GREEN}当前检测的域名： $domainname
${GREEN}证书有效期剩余天数:  ${RST}
${GREEN}不用担心，证书会自动更新 $NO_COLOR " 2>&1 | tee info
    elif [ $FLAG = "NO" ]; then
      echo -e "
$RED=====================================================
$RED              很遗憾，安装和配置失败
$RED=====================================================
${RED}由于证书申请失败，无法科学上网，请重装或更换一个域名重新安装， 详情：https://letsencrypt.org/docs/rate-limits/
进一步验证证书申请情况，参考：https://www.ssllabs.com/ssltest/${NO_COLOR}" 2>&1 | tee info
  fi
  touch /etc/motd
  cat info > /etc/motd
  fi
}
main
