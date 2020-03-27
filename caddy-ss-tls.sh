#!/bin/bash
mkdir /etc/caddy
mkdir /etc/ssl/caddy
mkdir /var/www
isRoot() {
    if [[ "$EUID" -ne 0 ]]; then
        echo "false"
    else
        echo "true"
    fi
}
init_release() {
    if [ -f /etc/os-release ]; then
        # freedesktop.org and systemd
        . /etc/os-release
        OS=$NAME
    elif type lsb_release >/dev/null 2>&1; then
        # linuxbase.org
        OS=$(lsb_release -si)
    elif [ -f /etc/lsb-release ]; then
        # For some versions of Debian/Ubuntu without lsb_release command
        . /etc/lsb-release
        OS=$DISTRIB_ID
    elif [ -f /etc/debian_version ]; then
        # Older Debian/Ubuntu/etc.
        OS=Debian
    elif [ -f /etc/SuSe-release ]; then
        # Older SuSE/etc.
        ...
    elif [ -f /etc/redhat-release ]; then
        # Older Red Hat, CentOS, etc.
        ...
    else
        # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
        OS=$(uname -s)
    fi

    # convert string to lower case
    OS=$(echo "$OS" | tr '[:upper:]' '[:lower:]')
    if [[ $OS == *'ubuntu'* || $OS == *'debian'* ]]; then
        PM='apt'
    elif [[ $OS == *'centos'* ]]; then
        PM='yum'
    else
        exit 1
    fi
    # PM='apt'
}
install_caddy() {
    curl https://getcaddy.com | bash -s personal
}
conf_caddy() {
    read -p "输入您的域名:" domainname
    read -p "域名输入正确吗？ (y/n)?: " answer
    if [ $answer != "y" ]; then
        read -p "重新输入域名:" domainname
    fi
    read -p "输入您的邮箱，为了申请tls证书用的" domainname
    read -p "输入的邮箱正确吗？ (y/n)?: " answer
    if [ $answer != "y" ]; then
        echo "请重新输入您的邮箱："
        read emailname
    fi
    echo "http://$domainname:80 {
            redir https://$domainname:443{url}
         }
         https://$domainname:443 {
            gzip
            timeouts none
            tls $emailname
            root /var/www
            proxy / 127.0.0.1:8080
         }" >/etc/caddy/Caddyfile
}

install_supervisor() {
    init_release
    if [[ ${PM} == "apt" ]]; then
        apt-get install supervisor
        echo "[program:caddy]
command = /usr/local/bin/caddy -log stdout -agree=true -conf=/etc/caddy/Caddyfile
directory = /etc/caddy
autorstart=true
environment=CADDYPATH=/etc/ssl/caddy" >/etc/supervisor/conf.d/caddy.conf
    elif [[ ${PM} == "yum" ]]; then
        yum install supervisor
        echo "[program:caddy]
command = /usr/local/bin/caddy -log stdout -agree=true -conf=/etc/caddy/Caddyfile
directory = /etc/caddy
autorstart=true
environment=CADDYPATH=/etc/ssl/caddy" >/etc/supervisord.d/caddy.ini
    fi
}
main() {
    isRoot=$(isRoot)
    if [[ "${isRoot}" != "true" ]]; then
        echo -e "${RED_COLOR}error:${NO_COLOR}Please run this script as as root"
        exit 1
    else
        install_caddy
        conf_caddy
        install_supervisor
        systemctl enable supervisord             # 开机自启动
        systemctl start supervisord              # 启动supervisord服务 （supervisord -c /etc/supervisord.conf ）
        systemctl status supervisord             # 查看supervisord服务状态
        ps -ef | grep supervisord                # 查看是否存在supervisord进程
        supervisorctl -c /etc/supervisord.conf   #查看进程中的任务
        echo "caddy 安装和配置成功
            启动：supervisorctl start caddy
            停止：supervisorctl stop caddy
            重启：supervisorctl restart caddy
            查看状态：supervisorctl status"
    fi
}
main


