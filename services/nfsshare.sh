#!/bin/bash
#   
#   Installiert den NFS Server und gibt das Verzeichnis `/data` frei.

echo "🚀 [INFO] Richte NFS Share /data ein"
sudo apt-get update
sudo apt-get install -y nfs-kernel-server

# Standard Verzeichnisse
sudo mkdir -p /data /home/ubuntu/templates /home/ubuntu/config
sudo chown -R ubuntu:ubuntu /data /home/ubuntu/templates /home/ubuntu/config
sudo chmod 777 /data

# Kompatibilitaet storage.sh
sudo ln -s /data /home/ubuntu/data

cat <<%EOF% | sudo tee /etc/exports
# /etc/exports: the access control list for filesystems which may be exported
#               to NFS clients.  See exports(5).
# Storage RW
/data *(rw,sync,no_subtree_check,all_squash,anonuid=1000,anongid=1000)
%EOF%
 
sudo exportfs -a
sudo systemctl restart nfs-kernel-server

echo "✅ [INFO] NFS Share /data erfolgreich eingerichtet!"