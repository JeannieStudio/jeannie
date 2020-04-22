#!/bin/bash
RED="\033[0;31m"
NO_COLOR="\033[0m"
GREEN="\033[32m\033[01m"
BLUE="\033[0;36m"
green(){
    echo -e "\033[32m\033[01m$1\033[0m"
}
isRoot(){
  if [[ "$EUID" -ne 0 ]]; then
    echo "false"
  else
    echo "true"
  fi
}
left_second(){
    seconds_left=15
    while [ $seconds_left -gt 0 ];do
      echo -n $seconds_left
      sleep 1
      seconds_left=$(($seconds_left - 1))
      echo -ne "\r     \r"
    done
}
main(){
   isRoot=$( isRoot )
  if [[ "${isRoot}" != "true" ]]; then
    echo -e "${RED_COLOR}error:${NO_COLOR}Please run this script as as root"
    exit 1
  else
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    rm -f /etc/domainname
    read -p "输入您的域名（注意：这个域名一定是您当前vps使用的域名）:" domainname
    echo "$domainname" 2>&1 | tee /etc/domainname
    rm -f /etc/RST.sh
    curl -s -o /etc/RST.sh https://raw.githubusercontent.com/JeannieStudio/jeannie/master/RST.sh
    chmod +x /etc/RST.sh
    echo -e "$GREEN 需要重启后才能生效，马上重启……"
    left_second
    reboot
  fi
}
main