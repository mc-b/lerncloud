#!/bin/bash
#   
#   Installiert die Microk8s Umgebung
#

# Basic Installation

sudo snap install microk8s --classic
sudo snap install kubectl --classic

####
# Abhandlung Container Cache

# Hostname ohne Nummer
HOST=$(hostname | cut -d- -f 1)

# Modul spezifische Images
if  [ -d /home/ubuntu/templates/cr-cache/${HOST} ]
then

    # Kubernetes Images 
    if  [ -d /home/ubuntu/templates/cr-cache/microk8s ]
    then
        for image in /home/ubuntu/templates/cr-cache/microk8s/*.tar
        do
            sudo microk8s ctr image import ${image}
        done
    fi

    for image in /home/ubuntu/templates/cr-cache/${HOST}/*.tar
    do
        sudo microk8s ctr image import ${image}
    done
fi
sudo microk8s ctr image list

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

# Persistente Datenablage
sudo microk8s kubectl apply -f https://raw.githubusercontent.com/mc-b/lerncloud/master/data/DataVolume.yaml

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

# AWS Hack - Hostname richtig setzen
export AWS_HOST=$(curl --max-time 2 http://169.254.169.254/latest/meta-data/public-hostname)
[ "${AWS_HOST}" != "" ] && { sudo hostname ${AWS_HOST}; }

