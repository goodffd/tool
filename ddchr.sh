#!/bin/bash

read -p "Please type new CHR Version: " version
read -sp "Please type Password for your new CHR: " password
echo " "
ip addr
read -p "Please type Network Interface: " netif

CHR_URL="https://download.mikrotik.com/routeros/${version}/chr-${version}.img.zip"

[ ! -e chr.img ] && wget -q --show-progress -O- "${CHR_URL}" | gunzip -c - > chr.img
LOOP_DEV=`losetup --show -Pf chr.img`
ADDRESS=`ip addr show ${netif} | grep global | cut -d' ' -f 6 | head -n 1`
GATEWAY=`ip route list | grep default | cut -d' ' -f 3`
DISK=`lsblk -oMOUNTPOINT,PKNAME -P | grep 'MOUNTPOINT="/"' | sed -re 's/(.*)PKNAME="(.*?)"$/\2/'`
[ -z $ADDRESS ] && read -p "Address (CIDR): " ADDRESS
[ -z $GATEWAY ] && read -p "Gateway address: " GATEWAY

echo "Address ${ADDRESS}"
echo "Gateway ${GATEWAY}"
echo "Target disk ${DISK} $(lsblk -oKNAME,MOUNTPOINT,MODEL -P | grep '${DISK}')"
read -ep "Is this ok (Y/n): " ANSWER
ANSWER=${ANSWER:=y}
[ ! ${ANSWER,,} == y ] && exit

[ ${version:0:1} = "6" ] && mount ${LOOP_DEV}p1 /mnt
[ ${version:0:1} = "7" ] && mount ${LOOP_DEV}p2 /mnt
echo "/user set 0 name=admin password=\"${password}\"" >> /mnt/rw/autorun.scr
echo "/ip address add address=$ADDRESS interface=ether1" >> /mnt/rw/autorun.scr
echo "/ip route add gateway=$GATEWAY" >> /mnt/rw/autorun.scr

dmesg -n 1 && umount /mnt && losetup -d $LOOP_DEV && echo u > /proc/sysrq-trigger && dd if=chr.img bs=32768 of=/dev/${DISK} conv=fsync && echo -e "\x1b[31mGOODBYE...\x1b[0m" && sleep 1 && echo b > /proc/sysrq-trigger
