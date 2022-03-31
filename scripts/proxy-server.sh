#!/bin/bash
#
#   Einrichten des Proxy Servers Privoxy - https://www.privoxy.org/ und ngrok Tunnels https://ngrok.com/
#
#   Client PC einrichten - https://www.heise.de/tipps-tricks/Einen-Proxy-Server-einrichten-so-klappt-s-4239868.html

# Proxy Server
sudo apt-get install -y privoxy

# wenn WireGuard installiert - Wireguard IP als Proxy IP
export ADDR=$(ip -f inet addr show wg0 | grep -Po 'inet \K[\d.]+')
[ "${ADDR}" = "" ] && { export ADDR=$(hostname -I | cut -d ' ' -f 1); }
sudo sed -i -e "s/127.0.0.1:8118/${ADDR}:8118/g" /etc/privoxy/config

sudo systemctl restart privoxy

# ngrok Tunnels
sudo snap install ngrok