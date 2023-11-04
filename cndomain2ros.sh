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

wget -N --no-check-certificate -O cndomain2ros.rsc https://cdn.jsdelivr.net/gh/blackmatrix7/ios_rule_script@master/rule/Clash/ChinaMax/ChinaMax_Domain_For_Clash.txt

cn_domain_filename="cndomain2ros.rsc"

#开始处理 cn_domain_filename 内容
sed -i '/^#/d' ${cn_domain_filename}
sed -i 's/\./\\\\./g; s/\(.*\)/add regexp="(\\\\.|^)\1\\$" type=FWD forward-to=$cndns/g' ${cn_domain_filename}
sed -i '1 i:local cndns 211.140.13.188' ${cn_domain_filename}
sed -i '2 i/ip dns static remove [/ip dns static find type=FWD]' ${cn_domain_filename}
sed -i '3 i/ip dns static' ${cn_domain_filename}
