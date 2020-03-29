#!/bin/bash
isRoot() {
  if [[ "$EUID" -ne 0 ]]; then
    echo "false"
  else
    echo "true"
  fi
}
main(){
  #check root permission
  isRoot=$( isRoot )
  if [[ "${isRoot}" != "true" ]]; then
    echo -e "非root用户不能执行该脚本"
    exit 1
  else
    sed -i 's/PermitRootLogin no/PermitRootLogin yes/g' /etc/ssh/sshd_config
    sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
    sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
    passwd root
    systemctl restart sshd.service
    systemctl enable sshd.service
    echo '修改成功，请用用户名root和刚设置好的密码登录vps吧，enjoy'
  fi
}
main
  

