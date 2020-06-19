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
${sudoCmd} systemctl stop gost.service
${sudoCmd} systemctl disable gost.service
${sudoCmd} rm -f /etc/systemd/system/gost.service
${sudoCmd} rm -f /etc/systemd/system/gost.service
while [ ! -f "/etc/systemd/system/gost.service" ]; do
    ${sudoCmd} wget -q -N https://raw.githubusercontent.com/goodffd/tool/master/gost.service -O /etc/systemd/system/gost.service
done
if [ ! -d "/etc/gost" ]; then
  mkdir /etc/gost
fi
while [ ! -f "/etc/gost/config.json" ]; do
  ${sudoCmd} wget -q -N https://raw.githubusercontent.com/goodffd/tool/master/gost-forward-config.json -O /etc/gost/config.json
done
${sudoCmd} systemctl enable gost.service
${sudoCmd} systemctl restart gost.service
