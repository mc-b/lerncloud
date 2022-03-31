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
sudo microk8s kubectl apply -f /var/snap/microk8s/current/args/cni-network/cni.yaml

###
# Zugriff fuer User ubuntu einrichten - funktioniert erst wenn microk8s laeuft
sudo usermod -a -G microk8s ubuntu
sudo mkdir -p /home/ubuntu/.kube
sudo microk8s config | sudo tee  /home/ubuntu/.kube/config
sudo chown -f -R ubuntu:ubuntu /home/ubuntu/.kube

###
# buildah Installieren
sh -c "echo 'deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_18.04/ /' | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list"
wget -nv https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/xUbuntu_18.04/Release.key -O /tmp/Release.key
sudo apt-key add - </tmp/Release.key
sudo apt-get update -qq
sudo apt-get -qq -y install buildah 
sudo apt-get -qq -y install fuse-overlayfs

SERVER_IP=$(sudo cat /var/lib/cloud/instance/datasource | cut -d: -f3 | cut -d/ -f3)
MASTER=$(hostname | cut -d- -f 3,4)

###
# Master vorhanden? - Join mit Master (nur wenn microk8s in Namen!)
if  [ "${SERVER_IP}" != "" ] && [ "${MASTER}" != "" ] && [[ "${MASTER}" == *"microk8s"* ]]
then

    # Master statt Worker Node mounten
    sudo umount /home/ubuntu/data
    sudo mount -t nfs ${SERVER_IP}:/data/storage/${MASTER} /home/ubuntu/data/
    sudo sed -i -e "s/$(hostname)/${MASTER}/g" /etc/fstab
    
    # loop bis Master bereit, Timeout zwei Minuten
    for i in {1..60}
    do
        if  [ -f /home/ubuntu/data/.ssh/id_rsa ]
        then
            # Password und ssh-key wie Master
            sudo chpasswd <<<ubuntu:$(cat /home/ubuntu/data/.ssh/passwd)
            cat /home/ubuntu/data/.ssh/id_rsa.pub >>/home/ubuntu/.ssh/authorized_keys
            # Node joinen
            sudo chmod 600 /home/ubuntu/data/.ssh/id_rsa
            echo $(ssh -i /home/ubuntu/data/.ssh/id_rsa -o StrictHostKeyChecking=no ${MASTER} microk8s add-node | awk 'NR==2 { print $0 }') >/tmp/join-${MASTER}
            sudo bash -x /tmp/join-${MASTER}
            sudo chmod 666 /home/ubuntu/data/.ssh/id_rsa
            break
        fi
        sleep 2
    done
fi

###
# Intro
    
cat <<%EOF% | sudo tee /home/ubuntu/README.md
    
### microk8s Kubernetes

[![](https://img.youtube.com/vi/v9KI2BAF5QU/0.jpg)](https://www.youtube.com/watch?v=v9KI2BAF5QU)

What is MicroK8s?
- - -

Weitere Informationen: [https://microk8s.io/](https://microk8s.io/)
  
%EOF%

