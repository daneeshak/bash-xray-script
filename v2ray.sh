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
            "email": "love@example.com",
            "flow": "xtls-rprx-vision",
            "level": 0
          }
        ],
        "decryption": "none",
        "fallbacks": [
          {
            "dest": "/dev/shm/trojan.sock",
            "xver": 1
          },
          {
            "path": "/trojanws",
            "dest": "/dev/shm/trojanws.sock",
            "xver": 1
          },
          {
            "path": "/websocket",
            "dest": "/dev/shm/websocket.sock",
            "xver": 1
          },
          {
            "path": "/vmesstcp",
            "dest": "/dev/shm/vmesstcp.sock",
            "xver": 1
          },
          {
            "path": "/vmessws",
            "dest": "/dev/shm/vmessws.sock",
            "xver": 1
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "tls",
        "tlsSettings": {
	 "minVersion": "1.2",
         "alpn": [
           "http/1.1"
          ],
          "certificates": [
            {
              "certificateFile": "/etc/xray/xray.crt",
              "keyFile": "/etc/xray/xray.key"
            }
          ]
        }
      }
    },
    {
      "listen": "/dev/shm/trojan.sock",
      "protocol": "trojan",
      "settings": {
        "clients": [
          {
            "password": "$UUID",
            "level": 0
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
      "listen": "/dev/shm/trojanws.sock",
      "protocol": "trojan",
      "settings": {
        "clients": [
          {
            "password": "$UUID",
	    "email": "trojanws",
	    "level" : 0
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
    },
    {
      "listen": "/dev/shm/websocket.sock",
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "email": "vlessws",
            "level": 0
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
      "listen": "/dev/shm/vmesstcp.sock",
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "email": "vmesstcp",
            "level": 0
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
      "listen": "/dev/shm/vmessws.sock",
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "email": "vmessws",
            "level": 0
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
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom"
    }
  ]
}
EOF

#accuring a ssl certificate (self-sigend openssl)

openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
    -subj /C=US/ST=Denial/L=Springfield/O=Dis/CN=dak.disnet.gq \
    -keyout xray.key  -out xray.crt
mkdir /etc/xray
cp xray.key /etc/xray/xray.key
cp xray.crt /etc/xray/xray.crt
chmod 644 /etc/xray/xray.key

#starting xray core on sytem startup

systemctl enable xray
systemctl restart xray

#install bbr

curl -LJO https://raw.githubusercontent.com/teddysun/across/master/bbr.sh
bash bbr.sh
