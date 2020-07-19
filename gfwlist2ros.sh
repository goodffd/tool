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
wget -N --no-check-certificate https://raw.githubusercontent.com/cokebar/gfwlist2dnsmasq/master/gfwlist2dnsmasq.sh && chmod +x gfwlist2dnsmasq.sh && sh ./gfwlist2dnsmasq.sh -l -o ./gfwlist_domain.rsc

gfwlist_domain_filename="gfwlist_domain.rsc"

#1、文件中域名的"."替换成"\\."
sed -i 's/\./\\\\./g' ${gfwlist_domain_filename}

#2、文件中每行行首增加字符串"add regexp="(\\.|^)"
sed -i 's/^/add regexp="(\\.|^)&/g' ${gfwlist_domain_filename}

#3、文件中每行行尾增加字符串"\$" type=FWD forward-to=$gfwdns"
sed -i 's/$/&\\$" type=FWD forward-to=$gfwdns/g' ${gfwlist_domain_filename}

#4、文件中在第1行前插入新行":local gfwdns 10.10.0.1"
sed -i '1 i:local gfwdns 10.10.0.1' ${gfwlist_domain_filename}

#5、文件中在第2行前插入新行"/ip dns static"
sed -i '2 i/ip dns static' ${gfwlist_domain_filename}

#6、文件中删除空行"
#sed -i '/^\s*$/d' ${gfwlist_domain_filename}
