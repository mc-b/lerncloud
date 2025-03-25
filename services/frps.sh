#!/bin/bash
#
# Installiert den FRP (Fast Reverse Proxy) und startet ihn als System Daemon

set -e

echo "🔑 Generiere FRP Token & Dashboard Passwort..."
export FRP_TOKEN=$(openssl rand -hex 16)
export DASHBOARD_PWD=$(openssl rand -hex 8)

echo "💾 Speichere Zugangsdaten in ~/data/.ssh/frp_secrets.env..."
cat <<EOF > ~/data/.ssh/frp_secrets.env
FRP_TOKEN=$FRP_TOKEN
DASHBOARD_PWD=$DASHBOARD_PWD
EOF
chmod 600 ~/data/.ssh/frp_secrets.env

echo "⬇️ Lade FRP Server herunter..."
TMP_DIR=$(mktemp -d)
wget -O "$TMP_DIR/frp.tar.gz" https://github.com/fatedier/frp/releases/latest/download/frp_0.61.2_linux_amd64.tar.gz
tar -xzf "$TMP_DIR/frp.tar.gz" -C "$TMP_DIR"
sudo mv "$TMP_DIR"/frp_*/frps /usr/local/bin/frps
sudo chmod +x /usr/local/bin/frps

echo "🛠️ Erstelle /etc/frp und Konfiguration..."
sudo mkdir -p /etc/frp
sudo tee /etc/frp/frps.ini > /dev/null <<EOF
[common]
bind_port = 7000
vhost_http_port = 80
vhost_https_port = 443
dashboard_port = 7500
dashboard_user = admin
dashboard_pwd = $DASHBOARD_PWD
token = $FRP_TOKEN
EOF
chmod 600 /etc/frp/frps.ini

echo "⚙️ Erstelle systemd Service..."
sudo tee /etc/systemd/system/frps.service > /dev/null <<EOF
[Unit]
Description=FRP Server
After=network.target

[Service]
Type=simple
EnvironmentFile=/home/$USER/data/.ssh/frp_secrets.env
ExecStart=/usr/local/bin/frps -c /etc/frp/frps.ini
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

echo "🚀 Starte frps Service..."
sudo systemctl daemon-reload
sudo systemctl enable frps
sudo systemctl start frps

echo "✅ Fertig! FRP läuft nun als Service."

