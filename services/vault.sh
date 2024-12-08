#!/bin/bash
#
#   Installiert und aktiviert eine HashiCorp Vault (Security Storage).
#

trap '' 1 3 9

# Installation
wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get -y update
sudo apt-get -y install vault

# Einrichten als Service
cat <<EOF | sudo tee /etc/systemd/system/vault-dev.service
[Unit]
Description=HashiCorp Vault Development Server
After=network-online.target

[Service]
Type=simple
WorkingDirectory=/home/ubuntu
User=ubuntu
Group=ubuntu
Environment="VAULT_DEV_ROOT_TOKEN_ID=insecure"
Environment="VAULT_UI_ENABLED=true"
Environment="VAULT_DEV_LISTEN_ADDRESS=0.0.0.0:8200"
ExecStart=/usr/bin/vault server -dev
ExecReload=/bin/kill -HUP \$MAINPID
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Start Service
sudo systemctl daemon-reload
sudo systemctl start vault-dev.service
