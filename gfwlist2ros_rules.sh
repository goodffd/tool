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
    ${sudoCmd} ${systemPackage} install bind-utils -y -qq
else
    ${sudoCmd} ${systemPackage} install dnsutils -y -qq
fi
${sudoCmd} ${systemPackage} install wget nginx -y -qq
wget -N --no-check-certificate https://raw.githubusercontent.com/cokebar/gfwlist2dnsmasq/master/gfwlist2dnsmasq.sh && chmod +x gfwlist2dnsmasq.sh && sh ./gfwlist2dnsmasq.sh -l -o ./gfwlist_domain.rsc

rm -f /usr/share/nginx/gfwlist_ip.rsc

while read -r line
do
  dig $line +short | tail -n 1 >> /usr/share/nginx/html/gfwlist_ip.rsc
done < gfwlist_domain.rsc

sort -n /usr/share/nginx/html/gfwlist_ip.rsc | uniq > /usr/share/nginx/html/gfwlist_ip_finall.rsc

gfwlist_ip_filename="gfwlist_ip_finall.rsc"

#开始处理 gfwlist_ip_filename 内容
#1、每行行首增加字符串"add action=lookup dst-address="
sed -i 's/^/add action=lookup dst-address=&/g' /usr/share/nginx/html/${gfwlist_ip_filename}

#2、每行行尾增加字符串" table=ros"
sed -i 's/$/& table=ros/g' /usr/share/nginx/html/${gfwlist_ip_filename}

#3、在文件第1行前插入新行"/log info "Loading gfwlist ipv4 route rules""
sed -i '1 i/log info "Loading gfwlist ipv4 route rules"' /usr/share/nginx/html/${gfwlist_ip_filename}

#4、在文件第2行前插入新行"/ip route rule remove [/ip route rule find table=ros]"
sed -i '2 i/ip route rule remove [/ip route rule find table=ros]' /usr/share/nginx/html/${gfwlist_ip_filename}

#5、在文件第3行前插入新行"/ip route rule"
sed -i '3 i/ip route rule' /usr/share/nginx/html/${gfwlist_ip_filename}
