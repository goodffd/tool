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

set_iptables_rules() {
      if ! iptables -C INPUT -s 27.122.57.247 -p tcp --dport 22 -j ACCEPT; then
           iptables -A INPUT -s 27.122.57.247 -p tcp --dport 22 -j ACCEPT
      fi
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
      if ! iptables -C INPUT -i lo -j ACCEPT; then
           iptables -A INPUT -i lo -j ACCEPT
      fi
      if ! iptables -C INPUT -p tcp --dport 22 -j DROP; then
           iptables -A INPUT -p tcp --dport 22 -j DROP
      fi
}

set_service_file() {
${sudoCmd} cat > /etc/systemd/system/server-confs.service <<-EOF
[Unit]
Description=Server confs service
After=network.target network-online.target nss-lookup.target
Wants=network-online.target

[Service]
ExecStart=/etc/server-confs.sh
Restart=on-failure

[Install]
WantedBy=default.target
EOF
}

${sudoCmd} ${systemPackage} install wget -y -qq
${sudoCmd} systemctl stop server-confs.service
${sudoCmd} systemctl disable server-confs.service
${sudoCmd} rm -f /etc/systemd/system/server-confs.service
${sudoCmd} rm -f /etc/systemd/system/server-confs.service

set_iptables_rules
set_service_file
${sudoCmd} systemctl enable server-confs.service
${sudoCmd} systemctl start server-confs.service
