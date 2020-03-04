#!/bin/bash
sudo curl https://getcaddy.com | bash -s personal 
sudo  apt-get install supervisor
sudo mkdir /etc/caddy
sudo mkdir /etc/ssl/caddy
sudo mkdir /var/www               
echo "请输入您的域名，例如：example.com："
read domainname
sudo mkdir /var/www/$domainname   
echo "请输入您的邮箱："
read emailname

echo "请输入端口号1-65535，但不能是443："
read port
echo "http://$domainname:80 {
      redir https://$domainname:$port{url}
} 
https://$domainname:443 {  
        gzip  
		tls $emailname
        root /var/www/$domainname 
        
}" > /etc/caddy/Caddyfile
sleep 10
echo "[program:caddy]
command = /usr/local/bin/caddy -agree -conf /etc/caddy/Caddyfile
process_name = caddy
stopwaitsecs = 11
directory = /usr/local/bin/caddy
redirect_stderr=true
stopwaitsecs = 11" > /etc/supervisor/conf.d/caddy.conf
 sleep 10

wget --no-check-certificate -O shadowsocks-all.sh https://raw.githubusercontent.com/teddysun/shadowsocks_install/master/shadowsocks-all.sh
chmod +x shadowsocks-all.sh
./shadowsocks-all.sh 2>&1 | tee shadowsocks-all.log

sed '4c "server_port":443,' /etc/shadowsocks-r/config.json
sleep 10
sed '14c "redirect": ["*:443#127.0.0.1:$port"],' /etc/shadowsocks-r/config.json
sleep 10
sudo /etc/init.d/shadowsocks-r restart

echo net.core.default_qdisc=fq >> /etc/sysctl.conf
echo net.ipv4.tcp_congestion_control=bbr >> /etc/sysctl.conf
sleep 10
sysctl -p
sleep 5
sudo supervisorctl reload
sleep 3
supervisorctl start caddy
echo "******************************
caddy 安装和配置成功
启动：supervisorctl start caddy  
停止：supervisorctl stop caddy    
重启：supervisorctl restart caddy  
查看状态：caddy -service status  
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

