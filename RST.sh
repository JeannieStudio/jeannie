#!/bin/bash
RED="\033[0;31m"
NO_COLOR="\033[0m"
GREEN="\033[32m\033[01m"
BLUE="\033[0;36m"
green(){
    echo -e "\033[32m\033[01m$1\033[0m"
}
/usr/bin/certbot-2 renew
sleep 2
/usr/sbin/nginx -s stop
sleep 2
/usr/sbin/nginx
sleep 2
end_time=$(echo | openssl s_client -servername $domainname -connect $domainname:443 2>/dev/null | openssl x509 -noout -dates |grep 'After'| awk -F '=' '{print $2}'| awk -F ' +' '{print $1,$2,$4 }' )
sleep 2
end_times=$(date +%s -d "$end_time")
sleep 2
now_time=$(date +%s -d "$(date | awk -F ' +'  '{print $2,$3,$6}')")
sleep 2
RST=$(($((end_times-now_time))/(60*60*24)))
sleep 2
sed -i "s/证书有效期剩余天数:  90/证书有效期剩余天数:  $RST/g" /etc/motd
