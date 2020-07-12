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
            "ServeNodes": [ "relay+tls://:13000/127.0.0.1:31664" ],
            "ChainNodes": []
        },
        {
            "ServeNodes": [ "relay+tls://:13001/127.0.0.1:32357" ],
            "ChainNodes": []
        },
        {
            "ServeNodes": [ "relay+tls://:13002/127.0.0.1:39446" ],
            "ChainNodes": []
        },
        {
            "ServeNodes": [ "relay+tls://:13003" ],
            "ChainNodes": []
        },
        {
            "ServeNodes": [ "relay://:13004/127.0.0.1:30888" ],
            "ChainNodes": []
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
${sudoCmd} rm -f /usr/bin/gost
get_gost
create_gost_config
create_gost_service
${sudoCmd} systemctl enable gost.service
${sudoCmd} systemctl start gost.service
