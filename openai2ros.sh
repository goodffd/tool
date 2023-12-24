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

${sudoCmd} wget -O OpenAI.list https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Shadowrocket/OpenAI/OpenAI.list
${sudoCmd} sed -rn 's/^DOMAIN-SUFFIX,(.*)/\1/p' OpenAI.list > openai_ds.txt
${sudoCmd} sed -rn 's/^DOMAIN-KEYWORD,(.*)/.*\1.*/p' OpenAI.list > openai_dk.txt
${sudoCmd} sed -rn '/^DOMAIN-SUFFIX,|^DOMAIN-KEYWORD,/!s/^DOMAIN,(.*)/\1/p' OpenAI.list > openai_d.txt


#生成ros L7
${sudoCmd} cat openai_d.txt openai_ds.txt openai_dk.txt > openai.txt
${sudoCmd} sort openai.txt | uniq > openai.rosL7
${sudoCmd} sed -i ':a;N;s/\n/|/g;ta' openai.rosL7
${sudoCmd} sed -i 's/^/"/g;s/$/"/g' openai.rosL7
${sudoCmd} sed -i 's/^/\/ip firewall layer7-protocol set [find name="openai"] regexp=/g' openai.rosL7



#生成ros dns v7.6之前
#${sudoCmd} sed -i 's/\./\\\\./g;s/\(.*\)/add regexp="(\\\\.|^)\1\\$" type=FWD forward-to=$netflix comment=NF/g' Netflix.list
#${sudoCmd} sed '=' Netflix.list | sed -r 'N;s/([^\n]+)\n(.*)/\2\1/' > Netflix.list.rosdns
#${sudoCmd} sed -i '1 i:local netflix 45.11.185.4' Netflix.list.rosdns
#${sudoCmd} sed -i '2 i/ip dns static remove [/ip dns static find comment~"NF.*"]' Netflix.list.rosdns
#${sudoCmd} sed -i '3 i/ip dns static' Netflix.list.rosdns

#生成ros dns v7.6之后
${sudoCmd} sed 's/\(.*\)/:do { add name="\1" type=FWD forward-to=$openai match-subdomain=yes address-list=openai comment=OpenAI } on-error={}/g' openai_d.txt > openai.dns
${sudoCmd} sed 's/\(.*\)/:do { add name="\1" type=FWD forward-to=$openai match-subdomain=yes address-list=openai comment=OpenAI } on-error={}/g' openai_ds.txt >> openai.dns
${sudoCmd} sed 's/\(.*\)/:do { add regexp="\1" type=FWD forward-to=$openai address-list=openai comment=OpenAI } on-error={}/g' openai_dk.txt >> openai.dns
${sudoCmd} sed -i '1 i:local openai 192.168.99.1' openai.dns
${sudoCmd} sed -i '2 i/ip dns static remove [/ip dns static find comment="OpenAI"]' openai.dns
${sudoCmd} sed -i '3 i/ip dns static' openai.dns
