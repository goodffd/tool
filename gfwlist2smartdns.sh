#!/bin/bash
_green() {
    printf '\033[1;31;32m'
    printf -- "%b" "$1"
    printf '\033[0m'
}

_red() {
    printf '\033[1;31;31m'
    printf -- "%b" "$1"
    printf '\033[0m'
}

_yellow() {
    printf '\033[1;31;33m'
    printf -- "%b" "$1"
    printf '\033[0m'
}

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
    ${sudoCmd} ${systemPackage} install bind-utils wget -y -q
else
    ${sudoCmd} ${systemPackage} install dnsutils wget -y -qq
fi

wget -N --no-check-certificate https://raw.githubusercontent.com/cokebar/gfwlist2dnsmasq/master/gfwlist2dnsmasq.sh && chmod +x gfwlist2dnsmasq.sh && sh ./gfwlist2dnsmasq.sh -l -o ./gfwlist_domain.conf

#增加额外需要加入gfwlist的域名
echo "libreswan.org" >> gfwlist_domain.conf
_green 'add some domains to gfwlist.\n'

_green 'start resolve domain.\n'

gfwlist_domain_filename="gfwlist_domain.conf"

#开始处理 gfwlist_domain_filename 内容
#1、每行行首增加字符串"nameserver /."
sed -i 's/^/add nameserver /.&/g' /etc/smartdns/${gfwlist_ip_filename}

#2、每行行尾增加字符串"/oversea"
sed -i 's/$/&/oversea/g' /etc/smartdns/${gfwlist_ip_filename}

_green 'all is done.\n'
