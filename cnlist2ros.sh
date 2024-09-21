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

wget -N --no-check-certificate -O ./all_cn_cidr.rsc https://ispip.clang.cn/all_cn_cidr.txt
wget -N --no-check-certificate -O ./all_cn_ipv6.rsc https://ispip.clang.cn/all_cn_ipv6.txt

cn_filename="all_cn_cidr.rsc"

cn_filename2="all_cn_ipv6.rsc"

#增加私有地址
#echo "192.168.0.0/16" >> ${cn_filename}
#echo "172.16.0.0/12" >> ${cn_filename}
#echo "10.0.0.0/8" >> ${cn_filename}

#开始处理 cn_filename 内容
#方法1
sed -i 's/\(.*\)/add address=\1 list=CN/g' ${cn_filename}
#方法2
#1、每行行首增加字符串"add address="
#sed -i 's/^/add address=&/g' ${cn_filename}

#2、每行行尾增加字符串" list=CN"
#sed -i 's/$/& list=CN/g' ${cn_filename}

#3、在文件第1行前插入新行"/log info "Loading CN ipv4 address list""
sed -i '1 i/log info "Loading CN ipv4 address list"' ${cn_filename}

#4、在文件第2行前插入新行"/ip firewall address-list remove [/ip firewall address-list find list=CN]"
sed -i '2 i/ip firewall address-list remove [/ip firewall address-list find list=CN]' ${cn_filename}

#5、在文件第3行前插入新行"/ip firewall address-list"
sed -i '3 i/ip firewall address-list' ${cn_filename}

#ipv6
sed -i 's/\(.*\)/add address=\1 list=CN/g' ${cn_filename2}
#在文件第1行前插入新行"/log info "Loading CN ipv6 address list""
sed -i '1 i/log info "Loading CN ipv6 address list"' ${cn_filename2}

#在文件第2行前插入新行"/ipv6 firewall address-list remove [/ipv6 firewall address-list find list=CN]"
sed -i '2 i/ipv6 firewall address-list remove [/ipv6 firewall address-list find list=CN]' ${cn_filename2}

#在文件第3行前插入新行"/ipv6 firewall address-list"
sed -i '3 i/ipv6 firewall address-list' ${cn_filename2}
