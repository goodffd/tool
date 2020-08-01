#!/bin/bash
if [[ $(/usr/bin/id -u) -ne 0 ]]; then
  sudoCmd="sudo"
else
  sudoCmd=""
fi

#copied & modified from atrandys trojan scripts
#copy from 秋水逸冰 ss scripts
if [[ -f /etc/redhat-release ]]; then
  release="centos"
  systemPackage="yum"
elif cat /etc/issue | grep -Eqi "debian"; then
  release="debian"
  systemPackage="apt-get"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
  release="ubuntu"
  systemPackage="apt-get"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
  release="centos"
  systemPackage="yum"
elif cat /proc/version | grep -Eqi "debian"; then
  release="debian"
  systemPackage="apt-get"
elif cat /proc/version | grep -Eqi "ubuntu"; then
  release="ubuntu"
  systemPackage="apt-get"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
  release="centos"
  systemPackage="yum"
fi

install_iptables() {
    if [[ "${systemPackage}" == "yum" ]]; then
        ${sudoCmd} systemctl stop firewalld
        ${sudoCmd} systemctl disable firewalld
        ${sudoCmd} ${systemPackage} install iptables-services -y -qq
    else
        ${sudoCmd} ${systemPackage} install iptables -y -qq
    fi
}

create_ssh-confs_shell() {
${sudoCmd} cat > /etc/ssh-confs.sh <<-EOF  
#!/bin/bash
common() {
      if ! iptables -C INPUT -s 92.38.189.201 -p tcp --dport 22 -j ACCEPT; then
           iptables -A INPUT -s 92.38.189.201 -p tcp --dport 22 -j ACCEPT
      fi
      if ! iptables -C INPUT -s 195.133.197.58 -p tcp --dport 22 -j ACCEPT; then
           iptables -A INPUT -s 195.133.197.58 -p tcp --dport 22 -j ACCEPT
      fi
      if ! iptables -C INPUT -s 103.72.4.233 -p tcp --dport 22 -j ACCEPT; then
           iptables -A INPUT -s 103.72.4.233 -p tcp --dport 22 -j ACCEPT
      fi
      if ! iptables -C INPUT -s 89.208.253.8 -p tcp --dport 22 -j ACCEPT; then
           iptables -A INPUT -s 89.208.253.8 -p tcp --dport 22 -j ACCEPT
      fi
      if ! iptables -C INPUT -s 154.17.2.166 -p tcp --dport 22 -j ACCEPT; then
           iptables -A INPUT -s 154.17.2.166 -p tcp --dport 22 -j ACCEPT
      fi
      if ! iptables -C INPUT -s 14.128.60.161 -p tcp --dport 22 -j ACCEPT; then
           iptables -A INPUT -s 14.128.60.161 -p tcp --dport 22 -j ACCEPT
      fi
      if ! iptables -C INPUT -s 103.102.5.81 -p tcp --dport 22 -j ACCEPT; then
           iptables -A INPUT -s 103.102.5.81 -p tcp --dport 22 -j ACCEPT
      fi
      if ! iptables -C INPUT -i lo -j ACCEPT; then
           iptables -A INPUT -i lo -j ACCEPT
      fi
      if ! iptables -C INPUT -p tcp --dport 22 -j DROP; then
           iptables -A INPUT -p tcp --dport 22 -j DROP
      fi
}
common &
sleep infinity
EOF
${sudoCmd} chmod +x /etc/ssh-confs.sh
}

create_ssh-confs_service() {
${sudoCmd} cat > /etc/systemd/system/ssh-confs.service <<-EOF
[Unit]
Description=ssh confs service
After=network.target network-online.target nss-lookup.target
Wants=network-online.target

[Service]
ExecStart=/etc/ssh-confs.sh
Restart=on-failure

[Install]
WantedBy=default.target
EOF
}

${sudoCmd} systemctl stop ssh-confs.service
${sudoCmd} systemctl disable ssh-confs.service
${sudoCmd} rm -f /etc/systemd/system/ssh-confs.service
${sudoCmd} rm -f /etc/systemd/system/ssh-confs.service
${sudoCmd} rm -f /etc/ssh-confs.sh
install_iptables
create_ssh-confs_shell
create_ssh-confs_service
${sudoCmd} systemctl enable ssh-confs.service
${sudoCmd} systemctl start ssh-confs.service
