#!/bin/bash
#
#   Aktiviert Wake on LAN 
#

sudo apt-get -y update
sudo apt-get install -y ethtool etherwake 

export ETH=$(ip link | awk -F: '$0 !~ "lo|vir|wl|tap|br|wg|docker0|^[^0-9]"{print $2;getline}')
export ETH=$(echo $ETH | sed 's/ *$//g')

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

