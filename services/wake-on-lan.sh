#!/bin/bash
#
#   Aktiviert Wake on LAN 
#

trap '' 1 3 9

# APT-Umgebung setzen, um interaktive Dialoge zu vermeiden
export DEBIAN_FRONTEND=noninteractive

sudo apt-get -y update
sudo apt-get install -y ethtool etherwake 

export ETH=$(ls -1 /sys/class/net/ | grep en | grep -v br | head -1)

# nur Aktivieren wenn unterstuetzt
sudo /sbin/ethtool -s ${ETH} wol g
if  [ $? -eq 0 ]
then

    cat <<EOF | sudo tee /etc/systemd/system/wol.service
[Unit]
Description=Configure Wake-up on LAN
After=network-online.target

[Service]
Type=oneshot
ExecStart=/sbin/ethtool -s ${ETH} wol g

[Install]
WantedBy=basic.target 
EOF

    sudo systemctl enable wol.service 
    sudo systemctl daemon-reload 
    sudo systemctl start wol.service 
fi
