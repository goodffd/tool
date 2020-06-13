#!/bin/sh

common() {
      sleep 5
      bash <(curl -s https://raw.githubusercontent.com/goodffd/tool/master/iptables.rules)
}

common &

sleep infinity
