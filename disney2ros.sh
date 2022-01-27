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
    ${sudoCmd} ${systemPackage} install wget bind-utils -y -q
else
    ${sudoCmd} ${systemPackage} install wget dnsutils -y -qq
fi

wget -O Disney.list https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Surge/Disney/Disney.list
sed -rni 's/^DOMAIN-SUFFIX,(.*)/\1/p' Disney.list

#生成ros L7
sed ':a;N;s/\n/|/g;ta' Disney.list > Disney.list.rosL7
sed -i 's/^/"/g;s/$/"/g' Disney.list.rosL7
sed -i "1 i/ip firewall layer7-protocol set [find name=disney] regexp=$(cat Disney.list.rosL7)" Disney.list.rosL7

#生成ros dns
sed -i 's/\./\\\\./g;s/\(.*\)/add regexp="(\\\\.|^)\1\\$" type=A address=$disney comment=DN/g' Disney.list
sed '=' Disney.list | sed -r 'N;s/([^\n]+)\n(.*)/\2\1/' > Disney.list.rosdns
sed -i "1 i:local disney $(dig tw6.dnsunlock.com +short)" Disney.list.rosdns
sed -i '2 i/ip dns static remove [/ip dns static find comment~"DN.*"]' Disney.list.rosdns
sed -i '3 i/ip dns static' Disney.list.rosdns
