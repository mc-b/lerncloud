#!/bin/bash
#

# neue Jupyter Umgebung, lokal auf VM
sudo apt-get install -y --no-install-recommends jupyter-notebook python3-venv uuid

# Python3 Libraries
sudo apt-get install -y python3-flask python3-setproctitle python3-requests python3-paho-mqtt \
                        python3-matplotlib python3-numpy python3-sklearn python3-pandas python3-seaborn 

cat <<%EOF% | sudo tee /etc/systemd/system/jupyter.service
[Unit]
Description=Jupyter Notebook

[Service]
Type=simple
PIDFile=/run/jupyter.pid
ExecStart=/usr/bin/jupyter notebook --ip=0.0.0.0 --port=32188 --no-browser --NotebookApp.token='' --NotebookApp.password=''
User=ubuntu
Group=ubuntu
WorkingDirectory=/home/ubuntu
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
%EOF%

sudo systemctl daemon-reload
sudo systemctl enable jupyter.service
sudo systemctl restart jupyter.service

# lernkube Public Key
curl https://raw.githubusercontent.com/mc-b/lerncloud/main/ssh/lerncloud >~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa

# SSH keine Verwendung von .ssh/known_hosts
cat <<EOF >~/.ssh/config
StrictHostKeyChecking no
UserKnownHostsFile /dev/null
LogLevel error
EOF

# Mount Verzeichnis
[ -d ~/data ] && { ln -s ~/data ~/work; } || { mkdir -p ~/work; }

# Public IP anhand Cloud Provider setzen, WireGuard ueberschreibt alle
cloud_provider=$(cloud-init query v1.cloud_name 2>/dev/null) 
case "$cloud_provider" in
    "aws")
        public_ip=$(cloud-init query ds.meta_data.public_ipv4 2>/dev/null)
        ;;
    "azure")
        public_ip=$(cloud-init query ds.meta_data.network.interface.0.ipv4.ipAddress.0.publicIpAddress 2>/dev/null)
        ;;
    "maas")
        public_ip=$(hostname).maas
        ;;        
    *)
        public_ip=$(hostname -I | cut -d ' ' -f 1) 
        ;;
esac
echo $public_ip >~/work/server-ip

# aktivieren wenn ohne OpenVPN gearbeitet wird
# wg_ip=$(ip -f inet addr show wg0 2>/dev/null | grep -Po 'inet \K[\d.]+') 
# [ "$wg_ip" != "" ] && { echo $wg_ip >~/work/server-ip; }

# Eindeutige UUID pro Installation fuer IoT
echo "UUID=\"$(uuid)\"" >~/work/uuid.py
