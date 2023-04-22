#!/bin/bash
#
#   Hilfsscript um einen MAAS Rack und Region Server zu installieren 
#

# MAAS installieren, User: ubuntu, PW: insecure
sudo apt-add-repository -y ppa:maas/3.3-next
sudo apt -y update
sudo apt install -y maas jq markdown nmap traceroute git curl wget zfsutils-linux cloud-image-utils virtinst qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils whois
sudo maas createadmin --username ubuntu --password insecure --email marcel.bernet@tbz.ch --ssh-import gh:mc-b
sudo snap refresh

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

export PROFILE=ubuntu
sudo maas apikey --username=$PROFILE | head -1 >/tmp/$$
maas login $PROFILE http://localhost:5240/MAAS/api/2.0 - < /tmp/$$
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
maas $PROFILE ipranges create type=dynamic start_ip="192.168.123.191" end_ip="192.168.123.254" 
maas $PROFILE vlan update "fabric-1" "untagged" dhcp_on=True primary_rack=$(hostname)
#maas $PROFILE vlan update "fabric-2" "untagged" dhcp_on=True primary_rack=$(hostname)

# Allgemeiner SSH Key einfuegen
maas $PROFILE sshkeys create "key=ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDPvLEdsh/Vpu22zN3M/lmLE8zEO1alk/aWzIbZVwXJYa1RbNHocyZlvE8XDcv1WqeuVqoQ2DPflkQxdrbp2G08AWYgPNiQrMDkZBHG4GlU2Jhe9kCRiWVx/oVDeK8v3+w2nhFt8Jk/eeQ1+E19JlFak1iYveCpHqa68W3NIWj5b10I9VVPmMJVJ4KbpEpuWNuKH0p0YsUKfTQdvrn42fz5jYS1aV7qCCOOzB3WC833QRy04iHZObxDWIi/IFeIp1Gw2FkzPhoZyx4Fk9bsXfm301IePp9cwzArI2LdcOhwEZ3RW2F7ie2WJlVy5tzJjMGCaE1tZTjiCahLNEeTiTQp public-key@cloud.tbz.ch"

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

