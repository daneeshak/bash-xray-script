#!/bin/bash

password=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-9};echo;)
rm -rf /etc/localtime
cp /usr/share/zoneinfo/Asia/Colombo /etc/localtime
date -R
apt purge iptables-persistent
apt install ufw
ufw allow 22/tcp
ufw allow 443/tcp
systemctl enable ufw
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
rm -rf /usr/local/etc/xray/config.json
cat << EOF > /usr/local/etc/xray/config.json
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": 443,
      "protocol": "trojan",
      "settings": {
        "clients": [
          {
            "password": "$password"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "grpc",
        "security": "tls",
        "tlsSettings": {
          "serverName": "t.co",
          "alpn": [
            "h2"
          ],
          "certificates": [
            {
              "certificateFile": "/etc/xray/xray.crt",
              "keyFile": "/etc/xray/xray.key"
            }
          ]
        },
        "grpcSettings": {
          "serviceName": "grpc"
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct"
    }
  ]
}
EOF
openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
    -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=www.example.com" \
    -keyout xray.key  -out xray.crt
mkdir /etc/xray
cp xray.key /etc/xray/xray.key
cp xray.crt /etc/xray/xray.crt
chmod 644 /etc/xray/xray.key

wget https://raw.githubusercontent.com/teddysun/across/master/bbr.sh
chmod +x bbr.sh
bash bbr.sh

systemctl enable xray
