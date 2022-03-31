#!/bin/bash
#
#	Kubernetes Join Worker
#

SERVER_IP=$(sudo cat /var/lib/cloud/instance/datasource | cut -d: -f3 | cut -d/ -f3)
MASTER=$(hostname | cut -d- -f 3,4)

# Master vorhanden?
if  [ "${SERVER_IP}" != "" ] && [ "${MASTER}" != "" ]
then

    # Master statt Worker Node mounten
    sudo umount /home/ubuntu/data
    sudo mount -t nfs ${SERVER_IP}:/data/storage/${MASTER} /home/ubuntu/data/
    sudo sed -i -e "s/$(hostname)/${MASTER}/g" /etc/fstab
    
    # Password und ssh-key wie Master
    sudo chpasswd <<<ubuntu:$(cat /home/ubuntu/data/.ssh/passwd)
    cat /home/ubuntu/data/.ssh/id_rsa.pub >>/home/ubuntu/.ssh/authorized_keys
    
    # loop bis Master bereit, Timeout zwei Minuten
    for i in {1..60}
    do
        if  [ -f /home/ubuntu/data/join-${MASTER}.sh ]
        then
            sudo bash -x /home/ubuntu/data/join-${MASTER}.sh
            break
        fi
        sleep 2
    done
fi

## Hinweis wie joinen, falls nicht geklappt

if [ -f /etc/kubernetes/kubelet.conf ]
then

    cat <<%EOF% | sudo tee README.md

### Kubernetes Worker Node

    Worker Node von Kubernetes ${MASTER} Master
  
%EOF%

else

    cat <<%EOF% | sudo tee README.md

### Kubernetes Worker Node

Um die Worker Node mit dem Master zu verbinden, ist auf dem Master folgender Befehl zu starten:
    
    sudo kubeadm token create --print-join-command
    
Dieser gibt den Befehl aus, der auf jedem Worker Node zu starten ist. 
  
%EOF%

fi

bash -x helper/intro
