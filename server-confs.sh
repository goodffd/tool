#!/bin/sh

common() {
      sleep 5
      if ! iptables -C INPUT -s 27.122.57.247 -p tcp --dport 22 -j ACCEPT; then
           iptables -A INPUT -s 27.122.57.247 -p tcp --dport 22 -j ACCEPT
      fi
      if ! iptables -C INPUT -s 92.38.189.201 -p tcp --dport 22 -j ACCEPT; then
           iptables -A INPUT -s 92.38.189.201 -p tcp --dport 22 -j ACCEPT
      fi
      if ! iptables -C INPUT -s 195.133.197.58 -p tcp --dport 22 -j ACCEPT; then
           iptables -A INPUT -s 195.133.197.58 -p tcp --dport 22 -j ACCEPT
      fi
      if ! iptables -C INPUT -s 103.72.4.233 -p tcp --dport 22 -j ACCEPT; then
           iptables -A INPUT -s 103.72.4.233 -p tcp --dport 22 -j ACCEPT
      fi
      if ! iptables -C INPUT -s 89.208.253.8 -p tcp --dport 22 -j ACCEPT; then
           iptables -A INPUT -s 89.208.253.8 -p tcp --dport 22 -j ACCEPT
      fi
      if ! iptables -C INPUT -s 154.17.2.166 -p tcp --dport 22 -j ACCEPT; then
           iptables -A INPUT -s 154.17.2.166 -p tcp --dport 22 -j ACCEPT
      fi
      if ! iptables -C INPUT -s 151.248.68.132 -p tcp --dport 22 -j ACCEPT; then
           iptables -A INPUT -s 151.248.68.132 -p tcp --dport 22 -j ACCEPT
      fi
      if ! iptables -C INPUT -s 185.172.113.241 -p tcp --dport 22 -j ACCEPT; then
           iptables -A INPUT -s 185.172.113.241 -p tcp --dport 22 -j ACCEPT
      fi
      if ! iptables -C INPUT -i lo -j ACCEPT; then
           iptables -A INPUT -i lo -j ACCEPT
      fi
      if ! iptables -C INPUT -p tcp --dport 22 -j DROP; then
           iptables -A INPUT -p tcp --dport 22 -j DROP
      fi
}

common &

sleep infinity
