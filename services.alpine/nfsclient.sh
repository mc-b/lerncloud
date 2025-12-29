#!/bin/bash
#   
#   Installiert den NFS Client und erzeugt /data Verzeichnis
#   Mountet evtl. vorhandene Server Folders

get_server_ip() {
  local ds

  if [ -f /etc/datasource.conf ]; then
    ds=/etc/datasource.conf
  elif [ -f /var/lib/cloud/instance/datasource ]; then
    ds=/var/lib/cloud/instance/datasource
  else
    return 1
  fi

  sed -n 's|.*http://\([^/:]*\).*|\1|p' "$ds" | head -n1
}
SERVER_IP="$(get_server_ip)"

apk update
apk add nfs-common

# Standard Verzeichnisse
mkdir -p /data /home/alpine/templates /home/alpine/config
chown -R alpine:alpine /data /home/alpine/templates /home/alpine/config
chmod 777 /data

# Kompatibilitaet storage.sh
ln -s /data /home/alpine/data

if  [ "${SERVER_IP}" != "" ]
then
    mount -t nfs ${SERVER_IP}:/data/config /home/alpine/config
    mount -t nfs ${SERVER_IP}:/data/templates /home/alpine/templates
    mount -t nfs ${SERVER_IP}:/data/storage /home/alpine/data
    
    # remount data mit neuem Verzeichnis data/${HOSTNAME}
    mkdir -p /home/alpine/data/${HOSTNAME} && chown alpine:alpine /home/alpine/data/${HOSTNAME} && chmod 777 /home/alpine/data/${HOSTNAME}
    umount /home/alpine/data
    mount -t nfs ${SERVER_IP}:/data/storage/${HOSTNAME} /home/alpine/data
    
    cat <<%EOF% | tee -a /etc/fstab
${SERVER_IP}:/data/templates            /home/alpine/templates  nfs defaults    0 11
${SERVER_IP}:/data/storage/${HOSTNAME}  /home/alpine/data       nfs defaults    0 12
%EOF%

fi
