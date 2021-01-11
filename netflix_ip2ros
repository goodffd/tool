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

if [ ${systemPackage} == "yum" ]; then
    ${sudoCmd} ${systemPackage} install wget -y -q
else
    ${sudoCmd} ${systemPackage} install wget -y -qq
fi

wget -N --no-check-certificate -O ./nfaws.rsc https://raw.githubusercontent.com/QiuSimons/Netflix_IP/master/getflix.txt


nf_filename="nfaws.rsc"


#开始处理 nf_filename 内容
sed -i 's/\(.*\)/add address=\1 list=netflix/g' ${nf_filename}

#1、在文件第1行前插入新行"/log info "Loading netflix ipv4 address list""
sed -i '1 i/log info "Loading netflix ipv4 address list"' ${nf_filename}

#2、在文件第2行前插入新行"/ip firewall address-list remove [/ip firewall address-list find list=netflix]"
sed -i '2 i/ip firewall address-list remove [/ip firewall address-list find list=netflix]' ${nf_filename}

#3、在文件第3行前插入新行"/ip firewall address-list"
sed -i '3 i/ip firewall address-list' ${nf_filename}
