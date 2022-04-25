#!/bin/bash
#   
#   Installiert den NFS Server und gibt das Verzeichnis `/data` frei.

sudo apt-get update
sudo apt install -y nfs-kernel-server

sudo mkdir -p /data 
sudo chown -R ubuntu:ubuntu /data
sudo chmod 777 /data

cat <<%EOF% | sudo tee /etc/exports
# /etc/exports: the access control list for filesystems which may be exported
#               to NFS clients.  See exports(5).
# Storage RW
/data *(rw,sync,no_subtree_check,all_squash,anonuid=1000,anongid=1000)
%EOF%
 
sudo exportfs -a
sudo systemctl restart nfs-kernel-server