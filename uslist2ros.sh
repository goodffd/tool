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
    ${sudoCmd} ${systemPackage} install nc -y -q
else
    ${sudoCmd} ${systemPackage} install netcat -y -qq
fi

echo ipv4 us | nc cc2asn.com 43 > all_us_cidr.rsc


us_filename="all_us_cidr.rsc"


#开始处理 us_filename 内容
#方法1
sed -i 's/\(.*\)/add address=\1 list=US/g' ${us_filename}
#方法2
#1、每行行首增加字符串"add address="
#sed -i 's/^/add address=&/g' ${us_filename}

#2、每行行尾增加字符串" list=US"
#sed -i 's/$/& list=US/g' ${us_filename}

#3、在文件第1行前插入新行"/log info "Loading US ipv4 address list""
sed -i '1 i/log info "Loading US ipv4 address list"' ${us_filename}

#4、在文件第2行前插入新行"/ip firewall address-list remove [/ip firewall address-list find list=US]"
sed -i '2 i/ip firewall address-list remove [/ip firewall address-list find list=US]' ${us_filename}

#5、在文件第3行前插入新行"/ip firewall address-list"
sed -i '3 i/ip firewall address-list' ${us_filename}
