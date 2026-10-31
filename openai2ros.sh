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
MOSDNS_OUT="openaidomain2mosdns.txt"  # mosdns domain_set 输出
LIST="OpenAI.list"

export LC_ALL=C

${sudoCmd} wget -O "$LIST" https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Shadowrocket/OpenAI/OpenAI.list

#===== 一条 sed 提取：\1 为空即 DOMAIN，非空即 -SUFFIX / -KEYWORD =====
# map 保留三类，L7/DNS 只用前两类，mosdns 那份三类都要
sed -En 's/^DOMAIN(-SUFFIX|-KEYWORD)?,([^,]*).*/\1|\2/p' "$LIST" | sort -u > openai.map

#===== 生成 ROS L7（排除 DOMAIN-KEYWORD，它"含该字串即命中"，会误伤无关流量）=====
l7=$(grep -v '^-KEYWORD|' openai.map | cut -d'|' -f2 | sort -u | sed 's/\./\\\\./g' | paste -sd'|' -)
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

#===== 生成 mosdns domain_set（三类都保留，按 full -> domain -> keyword 排列）=====
{
  sed -En 's/^[|](.*)/full:\1/p'          openai.map
  sed -En 's/^-SUFFIX[|](.*)/domain:\1/p' openai.map
  sed -En 's/^-KEYWORD[|](.*)/keyword:\1/p' openai.map
} > "$MOSDNS_OUT"
