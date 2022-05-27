#!/bin/bash
#   
#   Installiert den NFS Client und erzeugt /data Verzeichnis

sudo apt-get update
sudo apt-get install -y nfs-common

# Standard Verzeichnisse
sudo mkdir -p /data /home/ubuntu/templates /home/ubuntu/config
sudo chown -R ubuntu:ubuntu /data /home/ubuntu/templates /home/ubuntu/config
sudo chmod 777 /data

# Kompatibilitaet storage.sh
sudo ln -s /data /home/ubuntu/data