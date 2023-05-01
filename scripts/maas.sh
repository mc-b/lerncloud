#!/bin/bash
#
#   Hilfsscript um einen MAAS Rack und Region Server zu installieren 
#

# MAAS installieren, User: ubuntu, PW: insecure
sudo apt-add-repository -y ppa:maas/3.3-next
sudo apt -y update
sudo apt install -y maas jq markdown nmap traceroute git curl wget zfsutils-linux cloud-image-utils virtinst qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils whois

# Password ist 'insecure'
echo "insecure" >/home/ubuntu/.ssh/passwd
sudo chpasswd <<<ubuntu:$(cat /home/ubuntu/.ssh/passwd)

# NFS
sudo apt-get update
sudo apt-get install -y nfs-kernel-server

sudo rm -f /data
sudo mkdir -p /data /data/storage /data/config /data/templates /data/config/wireguard /data/config/ssh /data/templates/cr-cache
sudo chown -R ubuntu:ubuntu /data
sudo chmod 777 /data/storage

cat <<%EOF% | sudo tee /etc/exports
# /etc/exports: the access control list for filesystems which may be exported
#               to NFS clients.  See exports(5).
# Storage RW
/data/storage 192.168.123.0/24(rw,sync,no_subtree_check,all_squash,anonuid=1000,anongid=1000)
/data/storage 10.244.0.0/16(rw,sync,no_subtree_check,all_squash,anonuid=1000,anongid=1000)
# Templates RO
/data/templates 192.168.123.0/24(ro,sync,no_subtree_check)
/data/templates 10.244.0.0/16(ro,sync,no_subtree_check)
# Config RO
/data/config 192.168.123.0/24(ro,sync,no_subtree_check)
/data/config 10.244.0.0/16(ro,sync,no_subtree_check)
%EOF%
 
sudo exportfs -a
sudo systemctl restart nfs-kernel-server

# lernMAAS
cd $HOME
git clone https://github.com/mc-b/lernmaas.git
sudo cp lernmaas/preseeds/* /etc/maas/preseeds/
chmod +x lernmaas/helper/*
sudo cp lernmaas/helper/* /usr/local/bin/

# MAAS CLI Login durchfuehren 
cat <<%EOF% >>$HOME/.bashrc
export PROFILE=ubuntu
%EOF%

set -xe
export PROFILE=ubuntu
# MAAS User und Defaults setzen
RC=2
until [ $RC -eq 0 ]
do
    sudo maas createadmin --username $PROFILE --password insecure --email marcel.bernet@tbz.ch --ssh-import gh:mc-b
    RC=$?
done 

sudo maas apikey --username=$PROFILE | head -1 >/tmp/$$
RC=2
until [ $RC -eq 0 ]
do
    maas login $PROFILE http://localhost:5240/MAAS/api/2.0 - < /tmp/$$
    RC=$?
done    
rm /tmp/$$

# MAAS DNS forwarder setzen
export MY_NAMESERVER="208.67.222.222 208.67.220.22"
maas $PROFILE maas set-config name=upstream_dns value="$MY_NAMESERVER"

# Netzwerk Discovery ausschalten, mag AWS nicht
maas $PROFILE maas set-config name=network_discovery value=disabled
maas $PROFILE maas set-config name=active_discovery_interval value=0
maas $PROFILE maas set-config name=enable_analytics value=false

# Subnets aendern
export SUBNET_CIDR="192.168.123.0/24"
maas $PROFILE subnet update $SUBNET_CIDR gateway_ip="192.168.123.1"
maas $PROFILE subnet update $SUBNET_CIDR dns_servers="$MY_NAMESERVER"

# Enable DHCP
maas $PROFILE ipranges create type=dynamic start_ip="192.168.123.190" end_ip="192.168.123.253" 
maas $PROFILE vlan update "fabric-1" "untagged" dhcp_on=True primary_rack=$(hostname)

# Allgemeiner SSH Key einfuegen
maas $PROFILE sshkeys create "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDUHol1mBvP5Nwe3Bzbpq4GsHTSw96phXLZ27aPiRdrzhnQ2jMu4kSgv9xFsnpZgBsQa84EhdJQMZz8EOeuhvYuJtmhAVzAvNjjRak+bpxLPdWlox1pLJTuhcIqfTTSfBYJYB68VRAXJ29ocQB7qn7aDj6Cuw3s9IyXoaKhyb4n7I8yI3r0U30NAcMjyvV3LYOXx/JQbX+PjVsJMzp2NlrC7snz8gcSKxUtL/eF0g+WnC75iuhBbKbNPr7QP/ItHaAh9Tv5a3myBLNZQ56SgnSCgmS0EUVeMNsO8XaaKr2H2x5592IIoz7YRyL4wlOmj35bQocwdahdOCFI7nT9fr6f insecure@lerncloud"

# AZ (VPN) einrichten
if [ -d $HOME/config/$(hostname) ]
then

    for net in $HOME/config/$(hostname)/*.base64
    do
        zone=$(basename $net .base64)
        maas $PROFILE zones create name=$(echo ${zone} | tr '.' '-') description="$(cat ${net})"
    done

elif [ -d $HOME/config/az ]
then

    for net in $HOME/config/az/*.base64
    do
        zone=$(basename $net .base64)
        maas $PROFILE zones create name=$(echo ${zone} | tr '.' '-') description="$(cat ${net})"
    done
    
fi  

# evtl. Fehlermeldungen mit fehlendem Floppy Disk eleminieren
sudo rmmod floppy
echo "blacklist floppy" | sudo tee /etc/modprobe.d/blacklist-floppy.conf
sudo dpkg-reconfigure initramfs-tools