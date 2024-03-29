#!/bin/bash
#
#   Installiert die Virtualisierungsumgebung KVM inkl. virsh. 
#
# Testen
# virt-install --name=test-01 --ram=2048 --vcpus=1 --import --disk path=/vmdisks/ubuntu-22.04.img,format=qcow2 \
#              --disk path=/vmdisks/ubuntu-01.iso,device=cdrom --os-variant=ubuntu22.04 --network bridge=br0,model=virtio \
#              --graphics vnc,listen=0.0.0.0 --noautoconsole 

# KVM Installieren
sudo apt-get update -y
sudo apt-get install -y libvirt-daemon-system virtinst genisoimage
sudo usermod -aG libvirt ubuntu
sudo usermod -aG libvirt-qemu ubuntu

# Storage
sudo virsh pool-define-as --name default --type dir --target /vmdisks
sudo virsh pool-start --build default

# Network nur Bridge
sudo virsh net-destroy default
sudo virsh net-undefine default
cat <<EOF >/tmp/$$
<network>
  <name>default</name>
  <forward mode="bridge"/>
  <bridge name="br0"/>
</network>
EOF
sudo virsh net-define /tmp/$$
sudo virsh net-start default
sudo virsh net-autostart default

# Default Images
sudo wget -q -O /vmdisks/jammy-server-cloudimg-amd64.img https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
sudo qemu-img create -b /vmdisks/jammy-server-cloudimg-amd64.img -f qcow2 -F qcow2 /vmdisks/ubuntu-server-22.04.img 30G

# Default Cloud-init CD-ROM

echo -e "instance-id: ubuntu-server\nlocal-hostname: ubuntu-server" > meta-data
cat <<EOF >user-data
#cloud-config
password: insecure
chpasswd: { expire: False }
ssh_pwauth: true
disable_root: false
sudo: ALL=(ALL) NOPASSWD:ALL
ssh_import_id:
  - gh:mc-b
ssh_authorized_keys:
  - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDUHol1mBvP5Nwe3Bzbpq4GsHTSw96phXLZ27aPiRdrzhnQ2jMu4kSgv9xFsnpZgBsQa84EhdJQMZz8EOeuhvYuJtmhAVzAvNjjRak+bpxLPdWlox1pLJTuhcIqfTTSfBYJYB68VRAXJ29ocQB7qn7aDj6Cuw3s9IyXoaKhyb4n7I8yI3r0U30NAcMjyvV3LYOXx/JQbX+PjVsJMzp2NlrC7snz8gcSKxUtL/eF0g+WnC75iuhBbKbNPr7QP/ItHaAh9Tv5a3myBLNZQ56SgnSCgmS0EUVeMNsO8XaaKr2H2x5592IIoz7YRyL4wlOmj35bQocwdahdOCFI7nT9fr6f insecure@lerncloud
EOF
sudo genisoimage -output /vmdisks/cloud-init-template.iso -V cidata -r -J user-data meta-data

sudo chown -R libvirt-qemu:libvirt-qemu /vmdisks

# User virsh, wie MAAS.io
sudo useradd -s /bin/bash -d /home/virsh  -m virsh
sudo usermod -aG libvirt virsh
sudo usermod -aG libvirt-qemu virsh
sudo chpasswd <<<virsh:insecure
sudo mkdir /home/virsh/.ssh
curl https://raw.githubusercontent.com/mc-b/lerncloud/main/ssh/lerncloud.pub | sudo tee /home/virsh/.ssh/authorized_keys
sudo chown -R virsh:virsh /home/virsh
sudo chmod 700 /home/virsh/.ssh
sudo chmod 600 /home/virsh/.ssh/authorized_keys 

# Network Bridge

sudo apt-get install -y bridge-utils net-tools ethtool etherwake 
export ETH=$(ip link | awk -F: '$0 !~ "lo|vir|wl|tap|br|wg|docker0|^[^0-9]"{print $2;getline}')
export ETH=$(echo $ETH | sed 's/ *$//g')
export MAC=$(sudo ethtool -P ${ETH} | cut -d' ' -f3)

cat <<EOF | sudo tee /etc/netplan/50-cloud-init.yaml
network:
    version: 2
    ethernets:
        ${ETH}:
            dhcp4: false
            dhcp6: false
    bridges:
      br0:
       dhcp4: true
       interfaces:
         - ${ETH}
       macaddress: ${MAC}         
EOF

sudo sed -i -e 's/MACAddressPolicy=persistent/MACAddressPolicy=none/g' /usr/lib/systemd/network/99-default.link

sudo netplan generate
#sudo netplan apply - reboot in cloud-init Script vorsehen!

