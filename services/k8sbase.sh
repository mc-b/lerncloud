#!/bin/bash
#
#	Kubernetes Basis Installation
#
VERSION=1.21.2-00

# Deaktiviert permanent den SWAP Speicher - darf bei Kubernetes nicht aktiviert sein!

sudo swapoff -a
cat /etc/fstab | grep -v swap.img | sudo tee /etc/fstab
sudo rm -f /swap.img

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo apt-add-repository -y "deb http://apt.kubernetes.io/ kubernetes-bionic main"
sudo apt-get -q 2 update
sudo apt-get install -q 2 -y kubelet=${VERSION} kubeadm=${VERSION}
