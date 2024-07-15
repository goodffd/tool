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

#Get DouYin domain
${sudoCmd} wget -O DouYin.list https://cdn.jsdelivr.net/gh/blackmatrix7/ios_rule_script@master/rule/Surge/DouYin/DouYin.list
${sudoCmd} sed -rni 's/^DOMAIN-SUFFIX,(.*)/\1/p' DouYin.list

#Get Youku domain
${sudoCmd} wget -O Youku.list https://cdn.jsdelivr.net/gh/blackmatrix7/ios_rule_script@master/rule/Surge/Youku/Youku.list
${sudoCmd} sed -rni 's/^DOMAIN-SUFFIX,(.*)/\1/p' Youku.list

#生成ros L7
${sudoCmd} sed ':a;N;s/\n/|/g;ta' DouYin.list > DouYin.list.rosL7
${sudoCmd} sed -i 's/^/"/g;s/$/"/g' DouYin.list.rosL7
${sudoCmd} sed -i 's/^/\/ip firewall layer7-protocol set [find name=DouYin] regexp=/g' DouYin.list.rosL7

${sudoCmd} sed ':a;N;s/\n/|/g;ta' Youku.list > Youku.list.rosL7
${sudoCmd} sed -i 's/^/"/g;s/$/"/g' Youku.list.rosL7
${sudoCmd} sed -i 's/^/\/ip firewall layer7-protocol set [find name=Youku] regexp=/g' Youku.list.rosL7
