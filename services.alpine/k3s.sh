#!/bin/bash
#   
#   Installiert Rancher k3s ohne Ingress Controller traefik
#

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik" sh -s -

# alpine User als Admin zulassen
mkdir -p /home/alpine/.kube
cp /etc/rancher/k3s/k3s.yaml /home/alpine/.kube/config
chown -R alpine:alpine /home/alpine/.kube
chmod 700 /home/alpine/.kube
echo 'export KUBECONFIG=$HOME/.kube/config' >>/home/alpine/.bashrc 

# TODO Persistent Volumes und Claims einrichten - Daten werden auf MAAS Server /data/storage/$(hostname) gespeichert
