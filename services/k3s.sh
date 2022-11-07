#!/bin/bash
#   
#   Installiert Rancher k3s ohne Ingress Controller traefik
#

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik" sh -s -

# ubuntu User als Admin zulassen
sudo mkdir -p /home/ubuntu/.kube
sudo cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config
sudo chown -R ubuntu:ubuntu /home/ubuntu/.kube
sudo chmod 700 /home/ubuntu/.kube
sudo echo 'export KUBECONFIG=$HOME/.kube/config' >>/home/ubuntu/.bashrc 

# TODO Persistent Volumes und Claims einrichten - Daten werden auf MAAS Server /data/storage/$(hostname) gespeichert



