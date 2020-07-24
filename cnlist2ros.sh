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

${sudoCmd} ${systemPackage} install wget -y -qq
wget -N --no-check-certificate -O ./all_cn_cidr.rsc https://ispip.clang.cn/all_cn_cidr.txt
cp ./all_cn_cidr.rsc ./all_cn_cidr_rule.rsc

cn_filename1="all_cn_cidr.rsc"
#cn_filename2="all_cn_cidr_rule.rsc"

#开始处理 cn_filename1和2 内容
# cn_filename1
#1、每行行首增加字符串"add address="
sed -i 's/^/add address=&/g' ${cn_filename1}

#2、每行行尾增加字符串" list=CN"
sed -i 's/$/& list=CN/g' ${cn_filename1}

#3、在文件第1行前插入新行"/log info "Loading CN ipv4 address list""
sed -i '1 i/log info "Loading CN ipv4 address list"' ${cn_filename1}

#4、在文件第2行前插入新行"/ip firewall address-list remove [/ip firewall address-list find list=CN]"
sed -i '2 i/ip firewall address-list remove [/ip firewall address-list find list=CN]' ${cn_filename1}

#5、在文件第3行前插入新行"/ip firewall address-list"
sed -i '3 i/ip firewall address-list' ${cn_filename1}

# cn_filename2
#1、每行行首增加字符串"add action=lookup interface=gre-tunnel1 dst-address="
#sed -i 's/^/add action=drop interface=gre-tunnel1 dst-address=&/g' ${cn_filename2}

#2、每行行尾增加字符串" table=CN"
#sed -i 's/$/& table=CN/g' ${cn_filename2}

#3、在文件第1行前插入新行"/log info "Loading CN ipv4 rule""
#sed -i '1 i/log info "Loading CN ipv4 rule"' ${cn_filename2}

#4、在文件第2行前插入新行"/ip route rule remove [/ip route rule find table=CN]"
#sed -i '2 i/ip route rule remove [/ip route rule find table=CN]' ${cn_filename2}

#5、在文件第3行前插入新行"/ip route rule"
#sed -i '3 i/ip route rule' ${cn_filename2}
