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

${sudoCmd} wget -O Disney.list https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Surge/Disney/Disney.list
${sudoCmd} sed -rni 's/^DOMAIN-SUFFIX,(.*)/\1/p' Disney.list

#生成ros L7
${sudoCmd} sed ':a;N;s/\n/|/g;ta' Disney.list > Disney.list.rosL7
${sudoCmd} sed -i 's/^/"/g;s/$/"/g' Disney.list.rosL7
${sudoCmd} sed -i 's/^/\/ip firewall layer7-protocol set [find name=disney] regexp=/g' Disney.list.rosL7

#生成ros dns
${sudoCmd} sed -i 's/\./\\\\./g;s/\(.*\)/add regexp="(\\\\.|^)\1\\$" type=FWD forward-to=$disney comment=DN/g' Disney.list
${sudoCmd} sed '=' Disney.list | sed -r 'N;s/([^\n]+)\n(.*)/\2\1/' > Disney.list.rosdns
${sudoCmd} sed -i "1 i:local disney 45.11.185.4" Disney.list.rosdns
${sudoCmd} sed -i '2 i/ip dns static remove [/ip dns static find comment~"DN.*"]' Disney.list.rosdns
${sudoCmd} sed -i '3 i/ip dns static' Disney.list.rosdns
