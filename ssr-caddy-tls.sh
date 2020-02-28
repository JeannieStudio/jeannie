#!/bin/bash
curl https://getcaddy.com | bash -s personal
sudo mkdir /etc/caddy
sudo chown -R root:www-data /etc/caddy

sudo mkdir /etc/ssl/caddy
sudo chown -R www-data:root /etc/ssl/caddy
sudo chmod 0770 /etc/ssl/caddy    

sudo mkdir /var/www               
echo "请输入您的域名，例如：example.com："
read domainname
sudo mkdir /var/www/$domainname   
sudo chown -R www-data:www-data /var/www

curl -s https://raw.githubusercontent.com/mholt/caddy/master/dist/init/linux-systemd/caddy.service -o /etc/systemd/system/caddy.service
sudo systemctl daemon-reload
sudo systemctl enable caddy.service
sudo systemctl stop caddy.service 

echo "请输入您的邮箱："
read emailname
echo "请输入端口号1-65535，但不能是443："
read port
echo "$domainname {  
        gzip  
		tls $emailname
        root /var/www/$domainname 
		redir / https://$domainname/{uri} 301
        proxy / http://127.0.0.1:$port { 
                header_upstream Host {host}
                header_upstream X-Real-IP {remote}
                header_upstream X-Forwarded-For {remote}
                header_upstream X-Forwarded-Proto {scheme}
        }
}" > /etc/caddy/Caddyfile

systemctl restart caddy.service

wget --no-check-certificate -O shadowsocks-all.sh https://raw.githubusercontent.com/teddysun/shadowsocks_install/master/shadowsocks-all.sh
chmod +x shadowsocks-all.sh
./shadowsocks-all.sh 2>&1 | tee shadowsocks-all.log

sed '4c "server_port":$port,' /etc/shadowsocks-r/config.json
sudo /etc/init.d/shadowsocks-r restart

echo "******************************
caddy 安装和配置成功
启动：systemctl start caddy.service   
停止：systemctl stop caddy.service     
重启：systemctl restart caddy.service  
查看状态：systemctl status caddy.service   
安装目录为：/usr/local/bin/caddy 
配置文件位置：/etc/caddy/Caddyfile


*****************************************
ssr安装和配置成功
启动：/etc/init.d/shadowsocks-r start    
停止：/etc/init.d/shadowsocks-r stop     
重启：/etc/init.d/shadowsocks-r restart  
查看状态：/etc/init.d/shadowsocks-rstatus  
配置文件位置：/ets/shadowsocks-r/config 
"

