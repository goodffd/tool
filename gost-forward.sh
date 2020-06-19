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

create_gost_config() {
if [ ! -d "/etc/gost" ]; then
  mkdir /etc/gost
fi
${sudoCmd} cat > /etc/gost/config.json <<-EOF
{
    "Debug": false,
    "Retries": 0,
    "ServeNodes": [],
    "ChainNodes": [],
    "Routes": [
        {
            "ServeNodes": [ "tcp://:13001" ],
            "ChainNodes": [ "relay+tls://103.72.4.233:13001" ]
        },
        {
            "ServeNodes": [ "udp://:13001" ],
            "ChainNodes": [ "relay+mtls://103.72.4.233:13001" ]
        },
        {
            "ServeNodes": [ "tcp://:13002" ],
            "ChainNodes": [ "relay+tls://92.38.189.201:13002" ]
        },
        {
            "ServeNodes": [ "udp://:13002" ],
            "ChainNodes": [ "relay+mtls://92.38.189.201:13002" ]
        }

    ]
}
EOF
}

create_gost_service(){
${sudoCmd} cat > /etc/systemd/system/gost.service <<-EOF
[Unit]
Description=gost service
After=network.target network-online.target nss-lookup.target
Wants=network-online.target

[Service]
ExecStart=/usr/bin/gost -C /etc/gost/config.json
Restart=on-failure

[Install]
WantedBy=default.target
EOF
}

get_gost(){
  if [ ! -f "/usr/bin/gost" ]; then
      local API_URL="https://api.github.com/repos/ginuerzh/gost/releases/latest"
      local DOWNLOAD_URL="$(curl -H "Accept: application/json" -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:74.0) Gecko/20100101 Firefox/74.0" -s "${API_URL}" --connect-timeout 10| grep 'browser_download_url' | grep 'linux-amd64' | cut -d\" -f4)"
      ${sudoCmd} curl -L -H "Cache-Control: no-cache" -o "/tmp/gost.gz" "${DOWNLOAD_URL}"
      ${sudoCmd} gzip -d /tmp/gost.gz
      ${sudoCmd} mv /tmp/gost /usr/bin/gost
      ${sudoCmd} chmod +x /usr/bin/gost
  fi
}

${sudoCmd} ${systemPackage} install curl gzip -y -qq
${sudoCmd} systemctl stop gost.service
${sudoCmd} systemctl disable gost.service
${sudoCmd} rm -f /etc/systemd/system/gost.service
${sudoCmd} rm -f /etc/systemd/system/gost.service
${sudoCmd} rm -f /etc/gost/config.json
get_gost
create_gost_config
create_gost_service
${sudoCmd} systemctl enable gost.service
${sudoCmd} systemctl restart gost.service
