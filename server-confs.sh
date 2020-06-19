#!/bin/bash

common() {
    while [ ! iptables -C INPUT -p tcp --dport 22 -j DROP ]; do
      bash <(curl -s https://raw.githubusercontent.com/goodffd/tool/master/iptables-rules.sh)
    done
}

common &
sleep infinity
