#!/bin/bash
#   
#   Installiert die Microk8s Umgebung
#

# Basic Installation

#sudo snap install microk8s --classic --channel=1.24/stable
#sudo snap install kubectl --classic --channel=1.24/stable

sudo snap install microk8s --classic
sudo snap install kubectl --classic
sudo snap install helm --classic


###
# Add-ons  
sudo microk8s enable dns 

# hub.docker.com entfernen fuer Overlay Network calico
sudo sed -i -e 's|image: calico|image: quay.io/calico|g' /var/snap/microk8s/current/args/cni-network/cni.yaml
sudo sed -i -e 's|docker.io|quay.io|g' /var/snap/microk8s/current/args/cni-network/cni.yaml
sudo microk8s kubectl apply -f /var/snap/microk8s/current/args/cni-network/cni.yaml

###
# Zugriff fuer User ubuntu einrichten - funktioniert erst wenn microk8s laeuft
sudo usermod -a -G microk8s ubuntu
sudo mkdir -p /home/ubuntu/.kube
sudo microk8s config | sudo tee  /home/ubuntu/.kube/config
sudo chown -f -R ubuntu:ubuntu /home/ubuntu/.kube
sudo chmod 600 /home/ubuntu/.kube/config

# Persistente Datenablage (fix)
sudo microk8s kubectl apply -f https://raw.githubusercontent.com/mc-b/lerncloud/master/data/DataVolume.yaml
# Persistente Datenablage (flexibel)
sudo microk8s enable hostpath-storage

###
# Intro
    
cat <<%EOF% | sudo tee /home/ubuntu/README.md
    
### microk8s Kubernetes

[![](https://img.youtube.com/vi/v9KI2BAF5QU/0.jpg)](https://www.youtube.com/watch?v=v9KI2BAF5QU)

What is MicroK8s?
- - -

Weitere Informationen: [https://microk8s.io/](https://microk8s.io/)
  
%EOF%

sudo chown -f ubuntu:ubuntu /home/ubuntu/README.md


