#!/bin/bash

    sed -i 's/PermitRootLogin no/PermitRootLogin yes/g' /etc/ssh/sshd_config
    sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
    passwd root
    systemctl restart sshd.service
    systemctl enable sshd.service
    echo '修改成功，请用用户名root和刚设置好的密码登录vps吧，enjoy'
  

