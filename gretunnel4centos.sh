#!/bin/bash
#本脚本仅适用centos7以上
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

#加载gre模块
${sudoCmd} modprobe ip_gre
${sudoCmd} cat >>/etc/sysconfig/modules/ip_gre.modules <<-EOF
#!/bin/sh 
/sbin/modinfo -F filename ip_gre > /dev/null 2>&1 
if [ $? -eq 0 ]; then 
    /sbin/modprobe ip_gre
fi
EOF

${sudoCmd} chmod +x /etc/sysconfig/modules/ip_gre.modules
_yellow 'load gre module...done.\n'

#安装必要的软件
${sudoCmd} ${systemPackage} -y install epel-release -q
${sudoCmd} ${systemPackage} -y install net-tools bind-utils wget -q

#关闭网络管理（如果开启的话）
${sudoCmd} systemctl stop networkManager
${sudoCmd} systemctl disable networkManager

_yellow 'stop & disable networkManager...done.\n'

#关闭SELINUX
${sudoCmd} sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
${sudoCmd} sed -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/sysconfig/selinux

_yellow 'disable SELINUX...done.\n'

#关闭防火墙
${sudoCmd} systemctl stop firewalld.service
${sudoCmd} systemctl disable firewalld.service

_yellow 'stop & disable firewalld...done.\n'

#创建gre接口
local_ip=`ifconfig -a|grep -o -e 'inet [0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}'|grep -v "127.0.0"|awk '{print $2}'| head -n 1`
remote_ip=$(dig ipv4.fclouds.xyz @1.1.1.1 +short)
${sudoCmd} cat >/etc/sysconfig/network-scripts/ifcfg-tun0 <<-EOF 
DEVICE=tun0
ONBOOT=yes
TYPE=GRE
PEER_OUTER_IPADDR=${remote_ip}
PEER_INNER_IPADDR=10.10.0.2
MY_OUTER_IPADDR=${local_ip}
MY_INNER_IPADDR=10.10.0.1
BOOTPROTO=static
EOF

${sudoCmd} systemctl restart network
_yellow 'create gre interface...done.\n'

#安装并配置ipsec
${sudoCmd} ${systemPackage} install -y libreswan -q
${sudoCmd} systemctl enable ipsec

${sudoCmd} cat >/etc/ipsec.d/gre1.conf <<-EOF
conn gre1
    type=transport
    left=%defaultroute
    leftprotoport=gre
    right=${remote_ip}
    rightprotoport=gre
    ike=aes128-sha1;modp1024
    phase2alg=aes128-sha1,aes256-sha256
    nat-keepalive=yes
    keyingtries=30
    dpddelay=10
    dpdtimeout=120
    dpdaction=restart
    ikelifetime=8h
    keylife=24h
    pfs=no
    authby=secret
    auto=start
EOF

#创建预共享密码
${sudoCmd} ${systemPackage} install -y pwgen -q
psk=$(pwgen -1cny 10)
${sudoCmd} cat >/etc/ipsec.d/gre1.secrets <<-EOF
%any 0.0.0.0: PSK "${psk}"
EOF

${sudoCmd} ipsec restart

_yellow 'install ipsec for gre...done.\n'

#配置系统内核sysctl
${sudoCmd} cat >>/etc/sysctl.conf <<-EOF
#打开IP转发
net.ipv4.conf.all.forwarding = 1
net.ipv4.conf.default.forwarding = 1
net.ipv4.ip_forward = 1

#去除ICMP重定向警告
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.eth0.send_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.eth0.accept_redirects = 0

#去除 rp_filter 警告
net.ipv4.conf.all.rp_filter=0
net.ipv4.conf.default.rp_filter=0
net.ipv4.conf.eth0.rp_filter=0
net.ipv4.conf.erspan0.rp_filter=0
net.ipv4.conf.gre0.rp_filter=0
net.ipv4.conf.gretap0.rp_filter=0
net.ipv4.conf.ip_vti0.rp_filter=0
net.ipv4.conf.tun0.rp_filter=0

vm.overcommit_memory = 1
fs.file-max = 1000000
fs.inotify.max_user_instances = 8192
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1800
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.tcp_max_orphans = 32768
net.ipv4.tcp_rmem = 4096 87380 8388608
net.ipv4.tcp_wmem = 4096 87380 8388608
net.core.rmem_max = 8388608
net.core.wmem_max = 8388608
net.core.somaxconn = 32768
net.core.netdev_max_backlog = 32768
EOF

${sudoCmd} sysctl -p

_yellow 'set sysctl...done.\n'


#安装并配置smartdns
${sudoCmd} ${systemPackage} install -y curl tar -q
API_URL="https://api.github.com/repos/pymumu/smartdns/releases/latest"
DOWNLOAD_URL="$(curl -H "Accept: application/json" -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:74.0) Gecko/20100101 Firefox/74.0" -s "${API_URL}" --connect-timeout 10| grep 'browser_download_url' | grep 'x86_64-linux-all' | cut -d\" -f4)"
${sudoCmd} curl -L -H "Cache-Control: no-cache" -o "/tmp/smartdns.tar.gz" "${DOWNLOAD_URL}"
${sudoCmd} tar -zxf /tmp/smartdns.tar.gz -C /tmp
${sudoCmd} chmod +x /tmp/smartdns/install
${sudoCmd} /tmp/smartdns/install -i
${sudoCmd} systemctl stop smartdns.service
${sudoCmd} curl -sL https://raw.githubusercontent.com/goodffd/tool/master/smartdns.conf > /etc/smartdns/smartdns.conf 
${sudoCmd} systemctl start smartdns.service

#域名解析指向本地并加锁
echo "nameserver 127.0.0.1" > /etc/resolv.conf
${sudoCmd} chattr +i /etc/resolv.conf

_yellow 'install smartdns...done.\n'


#安装iptables
${sudoCmd} ${systemPackage} install -y iptables-services -q
${sudoCmd} systemctl enable iptables.service

is_exist=$(iptables-save | grep -- "-A POSTROUTING -o eth0 -j MASQUERADE")
if [[ -z "${is_exist}" ]]; then
    ${sudoCmd} iptables -t nat -I POSTROUTING -o eth0 -j MASQUERADE
fi

is_exist=$(iptables-save | grep -- "-A FORWARD -p tcp -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu")
if [[ -z "${is_exist}" ]]; then
    ${sudoCmd} iptables -t mangle -A FORWARD -p tcp -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
fi
${sudoCmd} service iptables save

_yellow 'install iptables & nat masquerdo & Change MSS...done.\n'


#配置自动更新gre和ipsec配置文件里的动态对端ip（ros侧）脚本
${sudoCmd} cat >/root/monitor.sh <<-"EOF"
#!/bin/bash
oldip=$(awk -F: '/PEER_OUTER_IPADDR/' /etc/sysconfig/network-scripts/ifcfg-tun0 | cut -d '=' -f 2)
newip=$(dig ipv4.fclouds.xyz @1.1.1.1 +short)
if [ "${oldip}" = "${newip}" ]; then
    echo "No Change IP!"
else
    sed -i '4c PEER_OUTER_IPADDR='${newip}'' /etc/sysconfig/network-scripts/ifcfg-tun0
    sed -i '5c \    right='${newip}'' /etc/ipsec.d/gre1.conf
    sleep 1
    systemctl restart network
    /sbin/ipsec restart
    ping 10.10.0.2 -c5
    echo "IP updated!"
fi
EOF
${sudoCmd} chmod +x /root/monitor.sh
echo "*/5 * * * * bash /root/monitor.sh" >> /var/spool/cron/root
${sudoCmd} systemctl restart crond

_yellow 'cron ddns scripts...done.\n'
