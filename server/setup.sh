#!/bin/bash
# Xray VPN Server Setup Script
# Ubuntu 22.04 LTS

set -e

DOMAIN=$1
EMAIL=$2

if [ -z "$DOMAIN" ] || [ -z "$EMAIL" ]; then
  echo "usage: bash setup.sh YOUR_DOMAIN YOUR_EMAIL"
  exit 1
fi

apt update && apt upgrade -y

curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh -o /tmp/install-xray.sh
bash /tmp/install-xray.sh install

ufw allow 80
ufw allow 443
ufw allow 22

apt install certbot -y
certbot certonly --standalone -d "$DOMAIN" --email "$EMAIL" --agree-tos --non-interactive

chmod 755 /etc/letsencrypt/live/
chmod 755 /etc/letsencrypt/archive/
chmod 644 /etc/letsencrypt/archive/"$DOMAIN"/*.pem

UUID=$(cat /proc/sys/kernel/random/uuid)
echo "uuid: $UUID"

cat > /usr/local/etc/xray/config.json << EOF
{
  "inbounds": [
    {
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$UUID"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "security": "tls",
        "tlsSettings": {
          "certificates": [
            {
              "certificateFile": "/etc/letsencrypt/live/$DOMAIN/fullchain.pem",
              "keyFile": "/etc/letsencrypt/live/$DOMAIN/privkey.pem"
            }
          ]
        },
        "wsSettings": {
          "path": "/vpn"
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

systemctl restart xray
systemctl enable xray
systemctl status xray

echo "vless://$UUID@$DOMAIN:443?encryption=none&security=tls&type=ws&path=%2Fvpn&sni=$DOMAIN#MyVPN"