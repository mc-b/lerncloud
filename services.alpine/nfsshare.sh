#!/bin/sh
#   
#   Installiert den NFS Server und gibt das Verzeichnis `/data` frei.

echo "🚀 [INFO] Richte NFS Share /data ein"
apk update
apk add nfs-utils

# Globale Mount Verzeichnisse - Kompatibilitaet zu lernmaas und lernvirt
sudo mkdir -p /data /data/storage /data/config /data/templates
sudo chown -R alpine:alpine /data
sudo chmod 777 /data

# Kompatibilitaet storage.sh
ln -s /data /home/alpine/data

cat <<%EOF% | tee /etc/exports
# /etc/exports: the access control list for filesystems which may be exported
#               to NFS clients.  See exports(5).
# Storage RW
/data *(rw,sync,no_subtree_check,all_squash,anonuid=1000,anongid=1000)
%EOF%
 
exportfs -rav
rc-update add rpcbind default
rc-update add nfs default

rc-service rpcbind start
rc-service nfs start

echo "✅ [INFO] NFS Share /data erfolgreich eingerichtet!"