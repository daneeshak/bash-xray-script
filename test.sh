#!/bin/bash

echo Enter a valid gen4 UUID:
read UUID

rm -rf /etc/localtime
cp /usr/share/zoneinfo/Asia/Colombo /etc/localtime
date -R


#updating and adding firewall rules

apt update
apt upgrade
apt purge iptables-persistent
apt install ufw
ufw allow 'OpenSSH'
ufw allow 443/tcp
ufw enable

bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

rm -rf /usr/local/etc/xray/config.json
cat << EOF > /usr/local/etc/xray/config.json
{
  "log": {
    "loglevel": "none"
  },
  "inbounds": [
    {
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "flow": "xtls-rprx-direct",
            "level": 0,
            "email": "love@example.com"
          }
        ],
        "decryption": "none",
        "fallbacks": [
          {
            "dest": 1310,
            "xver": 1
          },
          {
            "path": "/websocket",
            "dest": 1234,
            "xver": 1
          },
          {
            "path": "/vmesstcp",
            "dest": 2345,
            "xver": 1
          },
          {
            "path": "/vmessws",
            "dest": 3456,
            "xver": 1
          },
          {
            "path": "/trojanws",
            "dest": 4567,
            "xver": 1 
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "xtls",
        "xtlsSettings": {
          "alpn": [
            "http/1.1"
          ],
          "certificates": [
            {
              "certificateFile": "/etc/ssl/private/fullchain.cer",
              "keyFile": "/etc/ssl/private/private.key"
            }
          ]
        }
      }
    },
    {
      "port": 1310,
      "listen": "127.0.0.1",
      "protocol": "trojan",
      "settings": {
        "clients": [
          {
            "password": "$UUID",
            "level": 0,
            "email": "love@example.com"
          }
        ],
        "fallbacks": [
          {
            "dest": 80
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "none",
        "tcpSettings": {
          "acceptProxyProtocol": true
        }
      }
    },
    {
      "port": 1234,
      "listen": "127.0.0.1",
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "level": 0,
            "email": "love@example.com"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "acceptProxyProtocol": true,
          "path": "/websocket"
        }
      }
    },
    {
      "port": 2345,
      "listen": "127.0.0.1",
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "level": 0,
            "email": "love@example.com"
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "none",
        "tcpSettings": {
          "acceptProxyProtocol": true,
          "header": {
            "type": "http",
            "request": {
              "path": [
                "/vmesstcp"
              ]
            }
          }
        }
      }
    },
    {
      "port": 3456,
      "listen": "127.0.0.1",
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "level": 0,
            "email": "love@example.com"
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "acceptProxyProtocol": true,
          "path": "/vmessws"
        }
      }
    },
    {
      "port": 4567,
      "listen": "127.0.0.1",
      "protocol": "trojan",
      "settings": {
        "clients": [
          {
            "password": "$UUID",
            "level": 0,
            "email": "love@example.com"
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "acceptProxyProtocol": true,
          "path": "/trojanws"
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom"
    }
  ]
}
EOF

#starting xray core on sytem startup

systemctl enable xray
systemctl restart xray

#install bbr

curl -LJO https://raw.githubusercontent.com/teddysun/across/master/bbr.sh
bash bbr.sh
