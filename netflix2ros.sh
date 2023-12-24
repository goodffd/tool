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

${sudoCmd} wget -O Netflix.list https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Surge/Netflix/Netflix.list
#${sudoCmd} sed -rni 's/^DOMAIN-SUFFIX,(.*)/\1/p' Netflix.list
${sudoCmd} sed -rn 's/^DOMAIN-SUFFIX,(.*)/\1/p' Netflix.list > netflix_ds.txt
${sudoCmd} sed -rn 's/^DOMAIN-KEYWORD,(.*)/(\\\\.|^)\1+/p' Netflix.list > netflix_dk.txt
${sudoCmd} sed -rn '/^DOMAIN-SUFFIX,|^DOMAIN-KEYWORD,/!s/^DOMAIN,(.*)/\1/p' Netflix.list > netflix_d.txt


#生成ros L7
#${sudoCmd} sed ':a;N;s/\n/|/g;ta' Netflix.list > Netflix.list.rosL7
#${sudoCmd} sed -i 's/^/"/g;s/$/"/g' Netflix.list.rosL7
#${sudoCmd} sed -i 's/^/\/ip firewall layer7-protocol set [find name=netflix] regexp=/g' Netflix.list.rosL7
${sudoCmd} cat netflix_d.txt netflix_ds.txt netflix_dk.txt > netflix.txt
${sudoCmd} sort netflix.txt | uniq > netflix.rosL7
${sudoCmd} sed -i ':a;N;s/\n/|/g;ta' netflix.rosL7
${sudoCmd} sed -i 's/^/"/g;s/$/"/g' netflix.rosL7
${sudoCmd} sed -i 's/^/\/ip firewall layer7-protocol set [find name="netflix"] regexp=/g' netflix.rosL7



#生成ros dns v7.6之前
#${sudoCmd} sed -i 's/\./\\\\./g;s/\(.*\)/add regexp="(\\\\.|^)\1\\$" type=FWD forward-to=$netflix comment=NF/g' Netflix.list
#${sudoCmd} sed '=' Netflix.list | sed -r 'N;s/([^\n]+)\n(.*)/\2\1/' > Netflix.list.rosdns
#${sudoCmd} sed -i '1 i:local netflix 45.11.185.4' Netflix.list.rosdns
#${sudoCmd} sed -i '2 i/ip dns static remove [/ip dns static find comment~"NF.*"]' Netflix.list.rosdns
#${sudoCmd} sed -i '3 i/ip dns static' Netflix.list.rosdns

#生成ros dns v7.6之后
${sudoCmd} sed 's/\(.*\)/:do { add name="\1" type=FWD forward-to=$netflix match-subdomain=yes address-list=netflix comment=Netflix } on-error={}/g' netflix_d.txt > netflix.dns
${sudoCmd} sed 's/\(.*\)/:do { add name="\1" type=FWD forward-to=$netflix match-subdomain=yes address-list=netflix comment=Netflix } on-error={}/g' netflix_ds.txt >> netflix.dns
${sudoCmd} sed 's/\(.*\)/:do { add regexp="\1" type=FWD forward-to=$netflix address-list=netflix comment=Netflix } on-error={}/g' netflix_dk.txt >> netflix.dns
${sudoCmd} sed -i '1 i:local netflix 192.168.99.1' netflix.dns
${sudoCmd} sed -i '2 i/ip dns static remove [/ip dns static find comment="Netflix"]' netflix.dns
${sudoCmd} sed -i '3 i/ip dns static' netflix.dns
${sudoCmd} sed 's/\(.*\)/:do { add name="\1" type=FWD forward-to=$netflix match-subdomain=yes address-list=netflix comment=Netflix_v6 } on-error={}/g' netflix_d.txt > netflix.dnsv6
${sudoCmd} sed 's/\(.*\)/:do { add name="\1" type=FWD forward-to=$netflix match-subdomain=yes address-list=netflix comment=Netflix_v6 } on-error={}/g' netflix_ds.txt >> netflix.dnsv6
${sudoCmd} sed 's/\(.*\)/:do { add regexp="\1" type=FWD forward-to=$netflix address-list=netflix comment=Netflix_v6 } on-error={}/g' netflix_dk.txt netflix.dnsv6
${sudoCmd} sed -i '1 i:local netflix fdb0::1' netflix.dnsv6
${sudoCmd} sed -i '2 i/ip dns static remove [/ip dns static find comment="Netflix_v6"]' netflix.dnsv6
${sudoCmd} sed -i '3 i/ip dns static' netflix.dnsv6
