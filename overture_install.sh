#!/bin/bash
#本脚本可用于本地搭建overture，通过DomainFile和IP network file实现国内域名由国内dns解析，gfwlist域名由国外dns解析
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


#安装和配置overture
if [ ${systemPackage} == "yum" ]; then
    ${sudoCmd} ${systemPackage} install curl unzip -y -q
else
    ${sudoCmd} ${systemPackage} install curl unzip -y -qq
fi
API_URL="https://api.github.com/repos/shawn1m/overture/releases/latest"
DOWNLOAD_URL="$(curl -H "Accept: application/json" -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:74.0) Gecko/20100101 Firefox/74.0" -s "${API_URL}" --connect-timeout 10| grep 'browser_download_url' | grep 'linux-amd64' | cut -d\" -f4)"
${sudoCmd} curl -L -H "Cache-Control: no-cache" -o "/root/overture.zip" "${DOWNLOAD_URL}"
${sudoCmd} unzip -d /root/overture /root/overture.zip
${sudoCmd} mv /root/overture/overture-linux-amd64 /root/overture/overture
${sudoCmd} wget -N --no-check-certificate -O /root/overture/ip_network_primary_sample https://ispip.clang.cn/all_cn_cidr.txt
${sudoCmd} wget -N --no-check-certificate https://raw.githubusercontent.com/cokebar/gfwlist2dnsmasq/master/gfwlist2dnsmasq.sh && chmod +x gfwlist2dnsmasq.sh && sh ./gfwlist2dnsmasq.sh -l -o /root/overture/domain_alternative_sample
${sudoCmd} wget -N --no-check-certificate -O /root/overture/config.json https://raw.githubusercontent.com/goodffd/tool/master/overture_config.json

#域名解析指向本地并加锁
if [ ${release} == "centos" ]; then
    echo "nameserver 127.0.0.1" > /etc/resolv.conf
else
    ${sudoCmd} sed -i 's/#DNSStubListener=yes/DNSStubListener=no/g' /etc/systemd/resolved.conf
    ${sudoCmd} mv /etc/resolv.conf /etc/resolv.conf.bak
    echo "nameserver 127.0.0.1" > /etc/resolv.conf
fi
    ${sudoCmd} chattr +i /etc/resolv.conf
  
#创建systemd进程
cat > /etc/systemd/system/overture.service <<-EOF
[Unit]
Description=overture service
After=network.target network-online.target nss-lookup.target
Wants=network-online.target
[Service]
ExecStart=/root/overture/overture -c /root/overture/config.json
Restart=on-failure
[Install]
WantedBy=default.target
EOF

${sudoCmd} systemctl enable overture.service
${sudoCmd} systemctl start overture.service

#定时下载ip_network_primary_sample和domain_alternative_sample
if [ ${release} == "centos" ]; then
    echo "0 12 * * 1 wget -N --no-check-certificate -O /root/overture/ip_network_primary_sample https://ispip.clang.cn/all_cn_cidr.txt && wget -N --no-check-certificate https://raw.githubusercontent.com/cokebar/gfwlist2dnsmasq/master/gfwlist2dnsmasq.sh && chmod +x gfwlist2dnsmasq.sh && sh ./gfwlist2dnsmasq.sh -l -o /root/overture/domain_alternative_sample && systemctl restart overture.service" >> /var/spool/cron/root
else
    echo "0 12 * * 1 wget -N --no-check-certificate -O /root/overture/ip_network_primary_sample https://ispip.clang.cn/all_cn_cidr.txt && wget -N --no-check-certificate https://raw.githubusercontent.com/cokebar/gfwlist2dnsmasq/master/gfwlist2dnsmasq.sh && chmod +x gfwlist2dnsmasq.sh && sh ./gfwlist2dnsmasq.sh -l -o /root/overture/domain_alternative_sample && systemctl restart overture.service" >> /var/spool/cron/crontabs/root
fi

_green 'install overture...done.\n'
