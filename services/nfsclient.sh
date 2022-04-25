#!/bin/bash
#   
#   Installiert den NFS Client und erzeugt /data Verzeichnis

sudo apt-get update
sudo apt-get install -y nfs-common

sudo mkdir -p /data 
sudo chown -R ubuntu:ubuntu /data
sudo chmod 777 /data
