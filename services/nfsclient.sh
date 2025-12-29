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

sudo apt-get update
sudo apt-get install -y nfs-common

# Standard Verzeichnisse
sudo mkdir -p /data /home/ubuntu/templates /home/ubuntu/config
sudo chown -R ubuntu:ubuntu /data /home/ubuntu/templates /home/ubuntu/config
sudo chmod 777 /data

# Kompatibilitaet storage.sh
sudo ln -s /data /home/ubuntu/data

if  [ "${SERVER_IP}" != "" ]
then
    sudo mount -t nfs ${SERVER_IP}:/data/config /home/ubuntu/config
    sudo mount -t nfs ${SERVER_IP}:/data/templates /home/ubuntu/templates
    sudo mount -t nfs ${SERVER_IP}:/data/storage /home/ubuntu/data
    
    # remount data mit neuem Verzeichnis data/${HOSTNAME}
    sudo mkdir -p /home/ubuntu/data/${HOSTNAME} && chown ubuntu:ubuntu /home/ubuntu/data/${HOSTNAME} && chmod 777 /home/ubuntu/data/${HOSTNAME}
    sudo umount /home/ubuntu/data
    sudo mount -t nfs ${SERVER_IP}:/data/storage/${HOSTNAME} /home/ubuntu/data
    
    cat <<%EOF% | sudo tee -a /etc/fstab
${SERVER_IP}:/data/templates            /home/ubuntu/templates  nfs defaults    0 11
${SERVER_IP}:/data/storage/${HOSTNAME}  /home/ubuntu/data       nfs defaults    0 12
%EOF%

fi
