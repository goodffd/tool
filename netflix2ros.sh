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
UPSTREAM_DNS="192.168.16.8"    # 分流上游 DNS
L7_NAME="netflix"              # layer7-protocol 规则名
DNS_COMMENT="Netflix"          # dns static 标记注释
LIST="Netflix.list"

export LC_ALL=C

${sudoCmd} wget -O "$LIST" https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Surge/Netflix/Netflix.list

#===== 一条 sed 提取：\1 为空即 DOMAIN，非空即 -SUFFIX / -KEYWORD =====
# 这里的 keyword 是 apiproxy-device-prod-nlb- 这类长前缀，不是通用词，保留
sed -En 's/^DOMAIN(-SUFFIX|-KEYWORD)?,([^,]*).*/\1|\2/p' "$LIST" | sort -u > netflix.map

#===== 生成 ROS L7（三类合并，点全部转义）=====
l7=$(cut -d'|' -f2 netflix.map | sort -u | sed 's/\./\\\\./g' | paste -sd'|' -)
if [ -n "$l7" ]; then
  printf '/ip firewall layer7-protocol set [find name="%s"] regexp="%s"\n' "$L7_NAME" "$l7" > netflix.rosL7
else
  echo "未提取到域名，跳过 L7" >&2
fi

#===== 生成 ROS DNS (v7.6+ FWD)，按类型分派 =====
{
  printf ':local netflix %s\n' "$UPSTREAM_DNS"
  printf '/ip dns static remove [/ip dns static find comment="%s"]\n' "$DNS_COMMENT"
  printf '/ip dns static\n'
  # DOMAIN / DOMAIN-SUFFIX：name= 里必须是字面域名，不转义
  sed -En \
    -e "s/^[|](.*)/:do { add name=\"\1\" type=FWD forward-to=\$netflix address-list=$L7_NAME comment=$DNS_COMMENT } on-error={}/p" \
    -e "s/^-SUFFIX[|](.*)/:do { add name=\"\1\" type=FWD forward-to=\$netflix match-subdomain=yes address-list=$L7_NAME comment=$DNS_COMMENT } on-error={}/p" \
    netflix.map
  # DOMAIN-KEYWORD：走 regexp=，点先转义再套命令
  sed -En 's/^-KEYWORD[|](.*)/\1/p' netflix.map \
    | sed 's/\./\\\\./g' \
    | sed "s|.*|:do { add regexp=\"&\" type=FWD forward-to=\$netflix address-list=$L7_NAME comment=$DNS_COMMENT } on-error={}|"
} > netflix.dns
