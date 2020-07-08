#!/bin/sh

create_gost_config() {
cat > /etc/config/gost.json <<-EOF
{
    "Debug": false,
    "Retries": 0,
    "ServeNodes": [],
    "ChainNodes": [],
    "Routes": [
        {
            "ServeNodes": [ "tcp://:13000" ],
            "ChainNodes": [ "relay+tls://14.128.60.161:13000" ]
        },
        {
            "ServeNodes": [ "udp://:13000" ],
            "ChainNodes": [ "relay+tls://14.128.60.161:13000" ]
        },
        {
            "ServeNodes": [ "tcp://:13001" ],
            "ChainNodes": [ "relay+tls://89.208.253.8:13001" ]
        },
        {
            "ServeNodes": [ "udp://:13001" ],
            "ChainNodes": [ "relay+tls://89.208.253.8:13001" ]
        },
        {
            "ServeNodes": [ "tcp://:13002" ],
            "ChainNodes": [ "relay+tls://154.17.2.166:13002" ]
        },
        {
            "ServeNodes": [ "udp://:13002" ],
            "ChainNodes": [ "relay+tls://154.17.2.166:13002" ]
        }
    ]
}
EOF
}

create_gost_service() {
cat > /etc/init.d/gost <<-EOF
#!/bin/sh /etc/rc.common
START=99

USE_PROCD=1

start_service() {
    procd_open_instance
    procd_set_param command /usr/bin/gost -C /etc/config/gost.json
    procd_set_param respawn
    procd_close_instance
}

stop_service() {
    ps | grep "gost" | grep -v "grep" | awk '{print $1}' | xargs kill -s 9 > /dev/null 2>&1 &
}
EOF
chmod +x /etc/init.d/gost
}

get_gost() {
  if [ ! -f "/usr/bin/gost" ]; then
      local API_URL="https://api.github.com/repos/ginuerzh/gost/releases/latest"
      local DOWNLOAD_URL="$(curl -H "Accept: application/json" -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:74.0) Gecko/20100101 Firefox/74.0" -s "${API_URL}" --connect-timeout 10| grep 'browser_download_url' | grep 'linux-amd64' | cut -d\" -f4)"
      curl -L -H "Cache-Control: no-cache" -o "/tmp/gost.gz" "${DOWNLOAD_URL}"
      gzip -d /tmp/gost.gz
      mv /tmp/gost /usr/bin/gost
      chmod +x /usr/bin/gost
  fi
}

/etc/init.d/gost stop >/dev/null 2>&1
/etc/init.d/gost disable >/dev/null 2>&1
rm -f /etc/init.d/gost
rm -f /etc/init.d/gost
rm -f /etc/config/gost.json
rm -f /usr/bin/gost
get_gost
create_gost_config
create_gost_service
/etc/init.d/gost enable >/dev/null 2>&1
/etc/init.d/gost start >/dev/null 2>&1
