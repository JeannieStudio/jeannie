#! /bin/bash
# Author: Jeannie
#######color code########
RED="\033[0;31m"
NO_COLOR="\033[0m"
GREEN="\033[32m\033[01m"
BLUE="\033[0;36m"
FUCHSIA="\033[0;35m"
green(){
    echo -e "\033[32m\033[01m$1\033[0m"
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
check_status(){
  if [ -e "/usr/local/bin/caddy" -o -e "/usr/sbin/nginx"  -o -e "/usr/local/bin/trojan" -o -e "/usr/local/bin/caddy_old" -o -e "/etc/systemd/system/trojan.service" -o -e "/etc/systemd/system/caddy.service" ]; then
	    echo -e "${RED}检测到您尚未卸载，请先卸载再重装.${NO_COLOR}"
	    exit
  fi
}
uninstall(){
  init_release
    if [ -e "/usr/local/bin/caddy" ]; then
      caddy -service stop
      caddy -service uninstall
      rm -f /usr/local/bin/caddy
      rm - f /usr/local/bin/caddy_old
      rm -f /etc/systemd/system/caddy.service
    fi
    if [ -f "/usr/sbin/nginx" ]; then
        nginx -s stop
        if [ $PM = 'yum' ]; then
          yum remove -y nginx
        elif [ $PM = 'apt' ]; then
          apt autoremove -y nginx
        fi
    fi
    if [ -f "/usr/local/bin/trojan" ]; then
        systemctl stop trojan
        systemctl disable trojan
        rm -f /usr/local/bin/trojan
        rm -f /etc/systemd/system/trojan.service
    fi
    if [ -d "/var/www" ]; then
        rm -rf /var/www
    fi
    echo -e "${GREEN}恭喜您，卸载成功！！${NO_COLOR}"
}
install(){
  echo -e "${GREEN}1. 安装trojan+tls+caddy
${GREEN}2. 卸载
${GREEN}0. 啥也不做，退出${NO_COLOR}"
read -p "请输入您要执行的操作的数字:" aNum
case $aNum in
    1)check_status
      bash -c "$(curl -fsSL https://raw.githubusercontent.com/JeannieStudio/jeannie/master/trojan-caddy-test.sh)"
    ;;
    2)uninstall
    ;;
    0)exit
    ;;
    *)echo -e "${RED}输入错误！！！${NO_COLOR}"
      exit
    ;;
esac
}
main(){
  install
}
main
