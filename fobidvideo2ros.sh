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

if [ "${systemPackage}" = "yum" ]; then
    ${sudoCmd} ${systemPackage} install wget bind-utils -y -q
else
    ${sudoCmd} ${systemPackage} install wget dnsutils -y -qq
fi

#===== 提取域名 -> 转义点 -> 拼成一行 -> 套上 ROS 命令 =====
# 只取 DOMAIN / DOMAIN-SUFFIX；DOMAIN-KEYWORD 是"含该字串即命中"，放 L7 里会误伤
gen_l7() {
  local line
  line=$(sed -En 's/^DOMAIN(-SUFFIX)?,([^,]*).*/\2/p' "$2" | sort -u | sed 's/\./\\\\./g' | paste -sd'|' -)
  [ -n "$line" ] || { echo "$2: 未提取到域名，跳过" >&2; return 1; }
  printf '/ip firewall layer7-protocol set [find name="%s"] regexp="%s"\n' "$1" "$line" > "$2.rosL7"
}

export LC_ALL=C

${sudoCmd} wget -O DouYin.list https://cdn.jsdelivr.net/gh/blackmatrix7/ios_rule_script@master/rule/Surge/DouYin/DouYin.list
${sudoCmd} wget -O Youku.list https://cdn.jsdelivr.net/gh/blackmatrix7/ios_rule_script@master/rule/Surge/Youku/Youku.list

gen_l7 DouYin DouYin.list
gen_l7 Youku Youku.list
