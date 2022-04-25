#!/bin/bash
#   
#   Installiert den NFS Client und erzeugt /data Verzeichnis

sudo apt-get update
sudo apt-get install -y nfs-common

# Standard Verzeichnisse
sudo mkdir -p /home/ubuntu/data /home/ubuntu/templates /home/ubuntu/config
sudo chown -R ubuntu:ubuntu /home/ubuntu/data /home/ubuntu/templates /home/ubuntu/config
sudo chmod 777 /home/ubuntu/data

# /home/ubuntu/data fuer K8s Verfuegbar machen
sudo ln -s /home/ubuntu/data /data
