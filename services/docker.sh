#!/bin/bash
#   
#   Installiert Docker-CE
#

####
# Installation Docker 
sudo apt install -y docker.io
sudo usermod -aG docker ubuntu 

####
# Abhandlung Container Cache

# Hostname ohne Nummer
HOST=$(hostname | cut -d- -f 1)

# Modul spezifische Images
if  [ -d /home/ubuntu/templates/cr-cache/${HOST} ]
then

    # Kubernetes Images 
    if  [ -d /home/ubuntu/templates/cr-cache/k8s ]
    then
        for image in /home/ubuntu/templates/cr-cache/k8s/*.tar
        do
            sudo docker load -i ${image}
        done
    fi

    for image in /home/ubuntu/templates/cr-cache/${HOST}/*.tar
    do
        sudo docker load -i ${image}
    done
fi

sudo docker image ls

# Hack: Docker fuer Jenkins freischalten
sudo chmod o+rw /var/run/docker.sock