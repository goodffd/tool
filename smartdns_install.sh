#!/bin/bash
#本脚本可用于本地搭建smartdns，通过分组实现国内域名由国内dns解析，其他域名由国外dns解析
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


#安装和配置smartdns
if [ ${systemPackage} == "yum" ]; then
    ${sudoCmd} ${systemPackage} install curl tar -y -q
else
    ${sudoCmd} ${systemPackage} install curl tar -y -qq
fi
API_URL="https://api.github.com/repos/pymumu/smartdns/releases/latest"
DOWNLOAD_URL="$(curl -H "Accept: application/json" -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:74.0) Gecko/20100101 Firefox/74.0" -s "${API_URL}" --connect-timeout 10| grep 'browser_download_url' | grep 'x86_64-linux-all' | cut -d\" -f4)"
${sudoCmd} curl -L -H "Cache-Control: no-cache" -o "/tmp/smartdns.tar.gz" "${DOWNLOAD_URL}"
${sudoCmd} tar -zxf /tmp/smartdns.tar.gz -C /tmp
${sudoCmd} chmod +x /tmp/smartdns/install
${sudoCmd} /tmp/smartdns/install -i
${sudoCmd} systemctl stop smartdns.service
${sudoCmd} curl -sL https://raw.githubusercontent.com/goodffd/tool/master/smartdns_local.conf > /etc/smartdns/smartdns.conf
${sudoCmd} curl -sL https://goodffd.github.io/tool/china_domain.conf > /etc/smartdns/china_domain.conf
${sudoCmd} systemctl start smartdns.service

#域名解析指向本地并加锁
${sudoCmd} sed -i 's/#DNSStubListener=yes/DNSStubListener=no/g' /etc/systemd/resolved.conf
${sudoCmd} mv /etc/resolv.conf /etc/resolv.conf.bak
echo "nameserver 127.0.0.1" > /etc/resolv.conf
${sudoCmd} chattr +i /etc/resolv.conf

#定时下载china_domain.conf
if [ ${systemPackage} == "yum" ]; then
    echo "0 12 * * 1 wget -N --no-check-certificate -O /etc/smartdns/china_domain.conf https://goodffd.github.io/tool/china_domain.conf && systemctl restart smartdns.service" >> /var/spool/cron/root
else
    echo "0 12 * * 1 wget -N --no-check-certificate -O /etc/smartdns/china_domain.conf https://goodffd.github.io/tool/china_domain.conf && systemctl restart smartdns.service" >> /var/spool/cron/crontabs/root
fi

_green 'install smartdns...done.\n'
