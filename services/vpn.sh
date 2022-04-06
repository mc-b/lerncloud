#!/bin/bash
#
#   Installiert WireGuard
#

[ $# -eq 0 ] && { export LERNMAAS=/opt/wireguard; } || { export LERNMAAS=$1; } 

sudo add-apt-repository -y ppa:wireguard/wireguard
sudo apt-get update
sudo apt-get install -y wireguard 
sudo chmod 750 /etc/wireguard

# Aktivierung nur wenn Konfigurationsdatei = hostname vorhanden ist
if [ -f "/home/ubuntu/config/wireguard/$(hostname).conf" ]
then

    sudo cp /home/ubuntu/config/wireguard/$(hostname).conf /etc/wireguard/wg0.conf
    sudo chown root:root  /etc/wireguard/wg0.conf
    sudo chmod 600 /etc/wireguard/wg0.conf
    sudo systemctl enable wg-quick@wg0.service
    sudo systemctl start wg-quick@wg0.service
 
# Aktivierung durch MAAS AZ    
elif [ -f ${LERNMAAS}/wireguard ]
then

    export NO=$(hostname | cut -d- -f 2)
    if [ "${NO}" != "" ]
    then
        cd ${LERNMAAS}
        sed 's/ /\n/g' wireguard | base64 -d | sudo tar xzf - ${NO}.conf
        if  [ -f "${NO}.conf" ]
        then
            sudo mv ${NO}.conf /etc/wireguard/wg0.conf
            sudo systemctl enable wg-quick@wg0.service
            sudo systemctl start wg-quick@wg0.service            
        fi
    fi
fi    
