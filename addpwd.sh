#!/bin/bash
GREEN='\033[0;32m'  
NC='\033[0m' # No Color
isRoot() {
  if [[ "$EUID" -ne 0 ]]; then
    echo "false"
  else
    echo "true"
  fi
}
check_sys(){
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
    
      if [[ $release = 'ubuntu' || $release = 'debian' ]]; then
          PM='apt'
      elif [[ $release = *'centos'* ]]; then
          PM='yum'
      else
         exit 1
   fi
      # PM='apt'
}

install_wget(){
  check_sys
  #statements
  if [[ ${PM} = "apt" ]]; then
   #apt-get update  
    apt-get install wget 
  elif [[ ${PM} = "yum" ]]; then
   # yum update -y
    yum -y install wget
  fi
}
main(){
isRoot=$( isRoot )
if [[ "${isRoot}" != "true" ]]; then
    echo -e "${GREEN}error:${NC}Please run this script as as root"
    exit 1
  else
    install_wget
    sed -i 's/PermitRootLogin no/PermitRootLogin yes/g' /etc/ssh/sshd_config
    sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
    passwd root
    systemctl restart sshd.service
    systemctl enable sshd.service
    echo '修改成功，请用用户名root和刚设置好的密码登录vps吧，enjoy'
    }
main
