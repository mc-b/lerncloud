#!/bin/bash
#   
#   Installiert Samba, smb Dienst und gibt das HOME Verzeichnis frei
#
sudo apt-get install -y samba

# /home/ubuntu/data allgemein Freigeben
cat <<%EOF% | sudo tee -a /etc/samba/smb.conf
[global]
workgroup = smb
security = user
map to guest = Bad Password

[data]
path = /home/ubuntu/data 
public = yes
writable = yes
comment = Datenverzeichnis
printable = no
guest ok = yes
%EOF%

sudo systemctl restart smbd
