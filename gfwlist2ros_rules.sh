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

nginx_root="/usr/share/nginx/html"

rm -f ${nginx_root}/gfwlist_ip.rsc

#解析gfwlist域名并验证解析结果是否为合法的ip地址
while read -r line
do
  #将读取的每一行域名删除回车符、换行符
  line=`echo ${line} | tr -d '\n' | tr -d '\r'`
  #取dig answer段的最后一行解析结果（解析出来如果是有CNAME记录和ip记录，则ip记录是在最后行）
  ip=`dig ${line} +short | tail -n 1`
  #用ipcalc验证ip地址合法性（如果dig的结果为非ip地址，如CNAME，则判定为非合法的ip地址
  #ipcalc适用centos、unbuntu，不适用debian系统
  ipcalc -cs ${ip}
    if [ $? -eq 0 ]; then
     echo ${ip} >> ${nginx_root}/gfwlist_ip.rsc
    fi
done < gfwlist_domain.rsc

sort -n ${nginx_root}/gfwlist_ip.rsc | uniq > ${nginx_root}/gfwlist_ip_finall.rsc

gfwlist_ip_filename="gfwlist_ip_finall.rsc"

#开始处理 gfwlist_ip_filename 内容
#1、每行行首增加字符串"add action=lookup dst-address="
sed -i 's/^/add action=lookup dst-address=&/g' ${nginx_root}/${gfwlist_ip_filename}

#2、每行行尾增加字符串" table=ros"
sed -i 's/$/& table=ros/g' ${nginx_root}/${gfwlist_ip_filename}

#3、在文件第1行前插入新行"/log info "Loading gfwlist ipv4 route rules""
sed -i '1 i/log info "Loading gfwlist ipv4 route rules"' ${nginx_root}/${gfwlist_ip_filename}

#4、在文件第2行前插入新行"/ip route rule remove [/ip route rule find table=ros]"
sed -i '2 i/ip route rule remove [/ip route rule find table=ros]' ${nginx_root}/${gfwlist_ip_filename}

#5、在文件第3行前插入新行"/ip route rule"
sed -i '3 i/ip route rule' ${nginx_root}/${gfwlist_ip_filename}
