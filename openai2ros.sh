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

#===== 可调参数 =====
UPSTREAM_DNS="192.168.99.1"    # 分流上游 DNS
L7_NAME="openai"               # layer7-protocol 规则名
DNS_COMMENT="OpenAI"           # dns static 标记注释
LIST="OpenAI.list"

export LC_ALL=C

${sudoCmd} wget -O "$LIST" https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Shadowrocket/OpenAI/OpenAI.list

#===== 一条 sed 提取：\1 为空即 DOMAIN，-SUFFIX 即后缀域名 =====
# DOMAIN-KEYWORD 是"含该字串即命中"，L7 里会误伤无关流量，这里不取
sed -En 's/^DOMAIN(-SUFFIX)?,([^,]*).*/\1|\2/p' "$LIST" | sort -u > openai.map

#===== 生成 ROS L7（两类合并，点全部转义）=====
l7=$(cut -d'|' -f2 openai.map | sed 's/\./\\\\./g' | paste -sd'|' -)
if [ -n "$l7" ]; then
  printf '/ip firewall layer7-protocol set [find name="%s"] regexp="%s"\n' "$L7_NAME" "$l7" > openai.rosL7
else
  echo "未提取到域名，跳过 L7" >&2
fi

#===== 生成 ROS DNS (v7.6+ FWD)，按类型分派 =====
{
  printf ':local openai %s\n' "$UPSTREAM_DNS"
  printf '/ip dns static remove [/ip dns static find comment="%s"]\n' "$DNS_COMMENT"
  printf '/ip dns static\n'
  sed -En \
    -e "s/^[|](.*)/:do { add name=\"\1\" type=FWD forward-to=\$openai address-list=$L7_NAME comment=$DNS_COMMENT } on-error={}/p" \
    -e "s/^-SUFFIX[|](.*)/:do { add name=\"\1\" type=FWD forward-to=\$openai match-subdomain=yes address-list=$L7_NAME comment=$DNS_COMMENT } on-error={}/p" \
    openai.map
} > openai.dns
