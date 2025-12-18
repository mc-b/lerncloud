#!/bin/sh
#
#   Installiert WireGuard
#
echo "🚀 [INFO] Richte WireGuard ein"

apk update
apk add wireguard-tools

# Aktivierung nur wenn Konfigurationsdatei = hostname vorhanden ist
if [ -f "/etc/wireguard/$(hostname).conf" ]
then
    mv /etc/wireguard/$(hostname).conf /etc/wireguard/wg0.conf
    chown root:root  /etc/wireguard/wg0.conf
    chmod 600 /etc/wireguard/wg0.conf
    
    ln -s /etc/init.d/wg-quick /etc/init.d/wg-quick.wg0
    rc-service wg-quick.wg0 start

fi    

echo "✅ [INFO] WireGuard erfolgreich eingerichtet!"