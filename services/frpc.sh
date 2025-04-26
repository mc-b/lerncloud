#!/bin/bash
#
# Installiert den FRP (Fast Reverse Proxy) Client

set -e

echo "🚀 [INFO] Starte FRP (Fast Reverse Proxy) Client Installation..."

USER_HOME="/home/ubuntu"
FRP_DIR="$USER_HOME/data/frp"
INI_PATH="$FRP_DIR/frpc.ini"
SERVICE_DIR="$USER_HOME/.config/systemd/user"
SERVICE_PATH="$SERVICE_DIR/frpc.service"

echo "⬇️ [INFO] Lade FRP Client herunter..."
TMP_DIR=$(mktemp -d)
FRP_VERSION=$(curl -sI https://github.com/fatedier/frp/releases/latest | grep -i '^location:' | sed -E 's|.*/tag/v([^[:space:]]+)|\1|' | tr -d '\r')
wget -nv -O $TMP_DIR/frp.tar.gz https://github.com/fatedier/frp/releases/latest/download/frp_${FRP_VERSION}_linux_amd64.tar.gz
tar -xzf "$TMP_DIR/frp.tar.gz" -C "$TMP_DIR"
sudo mv "$TMP_DIR"/frp_*/frpc /usr/local/bin/frpc
sudo chmod +x /usr/local/bin/frpc

echo "📁 [INFO] Erstelle Konfigurationsverzeichnis: $FRP_DIR"
mkdir -p "$FRP_DIR"

echo "📝 [INFO] Erstelle generische frpc.ini unter $INI_PATH"
cat <<EOF > "$INI_PATH"
[common]
server_addr = <SERVER_IP>
server_port = 7000
token = <FRP_TOKEN>

[ssh]
type = tcp
local_ip = 127.0.0.1
local_port = 22
remote_port = 6000
EOF

echo "⚙️ [INFO] Erstelle systemd user service für frpc"
mkdir -p "$SERVICE_DIR"
cat <<EOF > "$SERVICE_PATH"
[Unit]
Description=FRP Client (User Service)
After=network.target

[Service]
Type=simple
WorkingDirectory=$USER_HOME
ExecStart=/usr/local/bin/frpc -c $INI_PATH
Restart=on-failure

[Install]
WantedBy=default.target
EOF

echo "🔄 [INFO] Systemd user daemon neuladen (für ubuntu)"
systemctl --user daemon-reload
systemctl --user enable frpc

echo "✅ [INFO] FRP Client ist eingerichtet als User-Service für ubuntu"
echo "❗ [INFO] Nicht gestartet. Zum Starten als ubuntu: systemctl --user start frpc"
