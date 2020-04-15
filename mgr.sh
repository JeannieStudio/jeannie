#!/bin/bash
RED="\033[0;31m"
NO_COLOR="\033[0m"
GREEN="\033[32m\033[01m"
BLUE="\033[0;36m"
green(){
    echo -e "\033[32m\033[01m$1\033[0m"
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
mgr(){
#=========安装的trojan+caddy+tls一键脚本==============================
if [ -e "/usr/local/bin/caddy" -a -e "/usr/local/bin/trojan" ]; then
	    ehco -e "${GREEN}系统检测到您目前安装的是trojan+caddy+tls一键脚本
${GREEN}1. 停止trojan
${GREEN}2. 重启trojan
${GREEN}3. 修改trojan密码
${GREEN}4. 停止caddy
${GREEN}5. 重启caddy
${GREEN}0. 啥也不做，退出${NO_COLOR}"
read -p "请输入您要执行的操作的数字:" aNum
case $aNum in
    1)systemctl stop trojan
    ;;
    2)systemctl restart trojan
    ;;
    3)systemctl stop trojan
      read -p "请输入您的trojan密码：" password
      while [ "${password}" = "" ]; do
            read -p "密码不能为空，请重新输入：" password
      done
      sed -i "8c \"$password\"," /usr/local/etc/trojan/config.json
      systemctl start trojan
    ;;
    4)caddy -service stop
    ;;
    5)caddy -service restart
    ;;
    0) exit
    ;;
    *)echo -e "${RED}输入错误！！！${NO_COLOR}"
      exit
    ;;
esac
fi
#=========安装的trojan+nginx+tls一键脚本===============================
if [ -e "/usr/sbin/nginx" -a -e "/usr/local/bin/trojan" ]; then
	    ehco -e "${GREEN}系统检测到您目前安装的是trojan+nginx+tls一键脚本
${GREEN}1. 停止trojan
${GREEN}2. 重启trojan
${GREEN}3. 修改trojan密码
${GREEN}4. 停止nginx
${GREEN}5. 重启nginx
${GREEN}0. 啥也不做，退出${NO_COLOR}"
read -p "请输入您要执行的操作的数字:" aNum
case $aNum in
    1)systemctl stop trojan
    ;;
    2)systemctl restart trojan
    ;;
    3)systemctl stop trojan
      read -p "请输入您的trojan密码：" password
      while [ "${password}" = "" ]; do
            read -p "密码不能为空，请重新输入：" password
      done
      sed -i "8c \"$password\"," /usr/local/etc/trojan/config.json
      systemctl start trojan
    ;;
    4)nginx -s stop
    ;;
    5)nginx
    ;;
    0) exit
    ;;
    *)echo -e "${RED}输入错误！！！${NO_COLOR}"
      exit
    ;;
esac
fi
#=========安装的v2ray+caddy+tls一键脚本==============================
if [ -e "/usr/local/bin/caddy" -a -e "/usr/bin/v2ray/v2ray" ]; then
	    ehco -e "${GREEN}系统检测到您目前安装的是v2ray+caddy+tls一键脚本
${GREEN}1. 停止v2ray
${GREEN}2. 重启v2ray
${GREEN}3. 修改UUID
${GREEN}4. 停止caddy
${GREEN}5. 重启caddy
${GREEN}0. 啥也不做，退出${NO_COLOR}"
read -p "请输入您要执行的操作的数字:" aNum
case $aNum in
    1)service v2ray stop
    ;;
    2)service v2ray restart
    ;;
    3)service v2ray stop
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
      \cp -rf config.json /etc/v2ray/config.json
      service v2ray start
    ;;
    4)caddy -service stop
    ;;
    5)caddy -service restart
    ;;
    0) exit
    ;;
    *)echo -e "${RED}输入错误！！！${NO_COLOR}"
      exit
    ;;
esac
fi
#=========安装的v2ray+nginx+tls一键脚本==============================
if [ -e "/usr/sbin/nginx" -a -e "/usr/bin/v2ray/v2ray" ]; then
	    ehco -e "${GREEN}系统检测到您目前安装的是v2ray+nginx+tls一键脚本
${GREEN}1. 停止v2ray
${GREEN}2. 重启v2ray
${GREEN}3. 修改UUID
${GREEN}4. 停止nginx
${GREEN}5. 重启nginx
${GREEN}0. 啥也不做，退出${NO_COLOR}"
read -p "请输入您要执行的操作的数字:" aNum
case $aNum in
    1)service v2ray stop
    ;;
    2)service v2ray restart
    ;;
    3)service v2ray stop
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
      \cp -rf config.json /etc/v2ray/config.json
      service v2ray start
    ;;
    4)nginx -s stop
    ;;
    5)nginx
    ;;
    0) exit
    ;;
    *)echo -e "${RED}输入错误！！！${NO_COLOR}"
      exit
    ;;
esac
fi
}
mgr
