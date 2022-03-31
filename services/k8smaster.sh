#!/bin/bash
#
#   Kubernetes Master Installation
#
HOME=/home/ubuntu

# obsolet durch Container Cache
# sudo kubeadm config images pull

# wenn WireGuard installiert - Wireguard IP als K8s IP verwenden
export ADDR=$(ip -f inet addr show wg0 | grep -Po 'inet \K[\d.]+')

if [ -f kubeadm.yaml ]
then
    sudo kubeadm init --config kubeadm.yaml 
else 
    if [ "${ADDR}" != "" ]
    then
            sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address ${ADDR} --apiserver-cert-extra-sans $(hostname -f)
    else
            if [ "$(hostname -I | cut -d ' ' -f 1)" != "10.0.2.15" ]
            then
                sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address $(hostname -I | cut -d ' ' -f 1) --apiserver-cert-extra-sans $(hostname -f)
            # vagrant
            else
                sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address $(hostname -I | cut -d ' ' -f 2) --apiserver-cert-extra-sans $(hostname -f)
            fi
    fi
fi    

sudo mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown -R ubuntu:ubuntu $HOME/.kube
         
# aus Kompatilitaet zur Vagrant Installation
sudo mkdir -p /home/vagrant/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo rm -f /home/ubuntu/data/.ssh/config
sudo cp -i /etc/kubernetes/admin.conf /home/ubuntu/data/.ssh/config

# ohne WireGuard FQDN verwenden
if [ "${ADDR}" == "" ]
then
    sudo sed -i -e "s/$(hostname -I | cut '-d ' -f1)/$(hostname -f)/g" /home/vagrant/.kube/config
    sudo sed -i -e "s/$(hostname -I | cut '-d ' -f1)/$(hostname -f)/g" /home/ubuntu/data/.ssh/config
    
fi    

# HACK: oeffnen fuer Web UI 
sudo chmod 755 /home/vagrant /home/vagrant/.kube
sudo chmod 644 /home/vagrant/.kube/config /home/ubuntu/data/.ssh/config

# this for loop waits until kubectl can access the api server that kubeadm has created
for i in {1..150}; do # timeout for 5 minutes
   kubectl get pods &> /dev/null
   if [ $? -ne 1 ]; then
      break
  fi
  sleep 2
done

# Pods auf Master Node erlauben
kubectl taint nodes --all node-role.kubernetes.io/master-

# Internes Pods Netzwerk (mit: --iface enp0s8, weil vagrant bei Hostonly Adapters gleiche IP vergibt)
sudo sysctl net.bridge.bridge-nf-call-iptables=1
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
  
# Standard Persistent Volume und Claim
kubectl apply -f https://raw.githubusercontent.com/mc-b/lernkube/master/data/DataVolume.yaml

# Join Command fuer Worker Nodes
if [ "${ADDR}" != "" ]
then
    # Replace WireGuard IP mit FQDN, sonst wird auf dem VPN zuviel Traffic erzeugt.
    sudo kubeadm token create --print-join-command | sed "s/${ADDR}/$(hostname -f)/g" >/data/join-$(hostname).sh
    
else
    sudo kubeadm token create --print-join-command >/data/join-$(hostname).sh
fi    

##########################
# Package Manager (HELM - Achtung bei Versionwechsel auch client.sh aendern).
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
helm repo add stable https://charts.helm.sh/stable
