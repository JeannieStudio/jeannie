#! /bin/bash
# Author: Jeannie
#######color code########
RED="\033[0;31m"
NO_COLOR="\033[0m"
GREEN="\033[0;32m"
BLUE="\033[0;36m"
FUCHSIA="\033[0;35m"
green(){
    echo -e "\033[32m\033[01m$1\033[0m"
}
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
echo "export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin:$PATH" >> ~/.bashrc
source ~/.bashrc
echo "先睡一会儿……"
sleep 3
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
  PID=$(ps -ef |grep "nginx" |grep "caddy"|grep -v "grep" |grep -v "init.d" |grep -v "service" |grep -v "caddy_install" |awk '{print $2}')
	[[ ! -z ${PID} ]] && kill -9 ${PID}
  init_release
  nginx -s stop
  if [ $PM = 'apt' ] ; then
    apt-get install -y dnsutils wget unzip zip curl tar git nginx certbot
  elif [ $PM = 'yum' ]; then
    yum -y install bind-utils wget unzip zip curl tar git nginx certbot
  fi
}
web_get(){
  rm -rf /var/www
  mkdir /var/www
  git clone https://github.com/JeannieStudio/Programming.git /var/www
}
nginx_conf(){
  green "=========================================="
  green "       开始申请证书"
  green "=========================================="
  read -p "请输入您的域名：" domainname
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
  certbot certonly --standalone --email $emailname -d $domainname
  curl -s -o /etc/nginx/conf.d/default.conf https://raw.githubusercontent.com/JeannieStudio/jeannie/master/default.conf
  sed -i "s/127.0.0.1/$domainname/g" /etc/nginx/conf.d/default.conf
}
trojan_install(){
  green "=========================================="
	green "       开始安装Trojan"
	green "=========================================="
  systemctl stop trojan
  rm -rf /usr/local/etc
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/trojan-gfw/trojan-quickstart/master/trojan-quickstart.sh)"
}
trojan_conf(){
  read -p "请输入您的trojan密码：" password
  sed -i "8c \"$password\"," /usr/local/etc/trojan/config.json
  cd /etc/letsencrypt/live/$domainname
  \cp fullchain.pem /usr/local/etc/trojan 2>&1 | tee /usr/local/etc/log
  \cp privkey.pem /usr/local/etc/trojan 2>&1 | tee /usr/local/etc/log
  sed -i "13c \"cert\":\"/usr/local/etc/trojan/fullchain.pem\"," /usr/local/etc/trojan/config.json
  sed -i "14c \"key\": \"/usr/local/etc/trojan/privkey.pem\"," /usr/local/etc/trojan/config.json
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
check_CA(){
    end_time=$(echo | openssl s_client -servername $domainname -connect $domainname:443 2>/dev/null | openssl x509 -noout -dates |grep 'After'| awk -F '=' '{print $2}'| awk -F ' +' '{print $1,$2,$4 }' )
    end_times=$(date +%s -d "$end_time")
    now_time=$(date +%s -d "$(date | awk -F ' +'  '{print $2,$3,$6}')")
    RST=$(($(($end_times-$now_time))/(60*60*24)))
}
main(){
  isRoot=$( isRoot )
  if [[ "${isRoot}" != "true" ]]; then
    echo -e "${RED}error:${NO_COLOR}Please run this script as as root"
    exit 1
  else
    tools_install
    nginx_conf
    nginx
    systemctl enable nginx.service
    #nginx -s quit
    web_get
    trojan_install
    echo "睡一会儿……"
    sleep 5
    trojan_conf
    systemctl start trojan
    systemctl enable trojan
    check_CA
	  grep "cp: cannot stat" /usr/local/etc/log >/dev/null
    if [ $? -eq 0 ]; then
        echo -e "
        $RED==========================================
	      $RED    很遗憾，Trojan安装和配置失败
	      $RED ==========================================
${RED}由于证书申请失败，无法科学上网，请重装或更换一个域名重新安装， 详情：https://letsencrypt.org/docs/rate-limits/
进一步验证证书申请情况，参考：https://www.ssllabs.com/ssltest/ $NO_COLOR" 2>&1 | tee info
      else
    green "=========================================="
	  green "       恭喜你，Trojan安装和配置成功"
	  green "=========================================="
         echo -e "
$BLUE 域名:         $GREEN ${domainname}
$BLUE 端口:         $GREEN 443
$BLUE 密码:         $GREEN ${password}
$BLUE 伪装网站请访问： $GREEN https://${domainname}
${GREEN}=========================================================
$BLUE Windows、macOS客户端请从这里下载： $GREEN  https://github.com/trojan-gfw/trojan/releases，
$BLUE 另外windows还需要下载v2ray-core：$GREEN https://github.com/v2ray/v2ray-core/releases
$BLUE ios客户端到应用商店下载：$GREEN shadowrocket;
$BLUE 安卓请下载igniter：$GREEN https://github.com/V2RaySSR/Trojan/releases
$BLUE 关注jeannie studio：$GREEN https://bit.ly/2X042ea
${GREEN}=========================================================
${GREEN}当前检测的域名： $domainname
${GREEN}证书有效期剩余天数:  ${RST} $NO_COLOR " 2>&1 | tee info
    fi
    touch /etc/motd
    cat info > /etc/motd
  fi
}
main
