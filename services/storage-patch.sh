#!/bin/bash
#   
#   Installation von iSCSI und deaktivieren von multipathd - wegen Probleme mit K8s bzw. longhorn
#   nur Verwenden, wenn kein SAN gebraucht wird.

# SAN Unterstuetzung
sudo systemctl stop multipathd
sudo systemctl disable multipathd
sudo systemctl mask multipathd

# iSCSI fuer longhorn.io

sudo apt-get install open-iscsi -y
sudo modprobe iscsi_tcp
lsmod | grep iscsi_tcp
echo "iscsi_tcp" | sudo tee /etc/modules-load.d/iscsi.conf

