#!/bin/bash
# 用官方的脚本安装caddy
sudo curl https://getcaddy.com | bash -s personal 

#安装进程管理工具superisor，帮助我们管理caddy服务的启动、停止、重启、查看状态
sudo  apt-get install supervisor

#创建一个目录存放caddy配置文件
sudo mkdir /etc/caddy

#创建一个目录存放tls证书，如果是caddy自动下载的证书则不会放在这个目录下
sudo mkdir /etc/ssl/caddy

#创建一个目录作为网站的根目录
sudo mkdir /var/www

#控制台提示输入域名
echo "请输入您的域名,例如:example.com:"

#读取内存中的字符串放在domainname变量中
read domainname

echo "您输入的域名正确吗?(y/n)"
read answer
if [ $answer != "y" ];then
	echo "请重新输入您的域名:"
	read domainname
fi
sudo mkdir /var/www/$domainname   
echo "请输入您的邮箱："
read emailname
echo "您输入的邮箱正确吗?(y/n)"
read answer
if [ $answer != "y" ];then
	echo "请重新输入您的邮箱："
	read emailname
fi

echo "请输入一个1-65535之间的端口号，但不能是443:"
read port
while [ $port == 443 -o $port -le 0 -o $port -gt 65535 ]
do
	echo "端口不能是443，且必须在1-65535之间。请重新输入:"
	read port
done

echo "https://$domainname:$port {  
        gzip  
	timeouts none
	tls $emailname
        root /var/www/$domainname     
}" > /etc/caddy/Caddyfile

echo "[program:caddy]
command = /usr/local/bin/caddy -log stdout -agree=true -conf=/etc/caddy/Caddyfile
directory = /etc/caddy
autorstart=true
environment=CADDYPATH=/etc/ssl/caddy" > /etc/supervisor/conf.d/caddy.conf
supervisord -c /etc/supervisor/supervisord.conf

wget --no-check-certificate -O shadowsocks-all.sh https://raw.githubusercontent.com/teddysun/shadowsocks_install/master/shadowsocks-all.sh
chmod +x shadowsocks-all.sh
./shadowsocks-all.sh 2>&1 | tee shadowsocks-all.log

#分别将配置/etc/shadowsocks-r/config.json文件的第4行和第14行改为下面内容
sed -i '4c "server_port":443,' /etc/shadowsocks-r/config.json
str=`awk -F: 'NR==1{print}'  /etc/caddy/Caddyfile`
port=$(echo $str|cut -c 27-30)
sed -i '14c "redirect": ["*:443#127.0.0.1:$port"],' /etc/shadowsocks-r/config.json

#改完后需要重启ssr
停止：/etc/init.d/shadowsocks-r stop 
启动：/etc/init.d/shadowsocks-r start    

#开启bbr
echo net.core.default_qdisc=fq >> /etc/sysctl.conf
echo net.ipv4.tcp_congestion_control=bbr >> /etc/sysctl.conf
sysctl -p

#控制台打印如下信息：
echo "******************************
caddy 安装和配置成功
启动：supervisorctl start caddy  
停止：supervisorctl stop caddy    
重启：supervisorctl restart caddy  
查看状态：supervisorctl status 
安装目录为：/usr/local/bin/caddy 
配置文件位置：/etc/caddy/Caddyfile
*****************************************
ssr安装和配置成功
启动：/etc/init.d/shadowsocks-r start    
停止：/etc/init.d/shadowsocks-r stop     
重启：/etc/init.d/shadowsocks-r restart  
查看状态：/etc/init.d/shadowsocks-rstatus  
配置文件位置：/etc/shadowsocks-r/config.json
"

