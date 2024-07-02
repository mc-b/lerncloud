#!/bin/bash
#
#   Nuetzliche Tools rund um Kubernetes
#

# Filtern von kubectl -o yaml

cd /tmp && wget -q https://github.com/itaysk/kubectl-neat/releases/download/v2.0.2/kubectl-neat_linux.tar.gz && \
    tar xzf kubectl-neat_linux.tar.gz && \
    sudo mv kubectl-neat /usr/local/bin && \
    rm kubectl-neat_linux.tar.gz

# Hierarchische Anzeige von Deployments, ReplicatSet und Pods

cd /tmp && wget -q https://github.com/tohjustin/kube-lineage/releases/download/v0.5.0/kube-lineage_linux_amd64.tar.gz && \
    tar xzf kube-lineage_linux_amd64.tar.gz && \
    sudo mv kube-lineage /usr/local/bin/ && \
    rm kube-lineage_linux_amd64.tar.gz 
    
# docker-compose nach Kubernetes
    
curl -L https://github.com/kubernetes/kompose/releases/download/v1.34.0/kompose-linux-amd64 -o kompose && \
    chmod +x kompose && \
    sudo mv ./kompose /usr/local/bin/kompose    
    
# K8s Cluster als Docker Container erstellen    
curl -Lo kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64 && \
    chmod +x kind && \
    sudo mv ./kind /usr/local/bin/kind 
    
# Schwachstellenscanner fuer Container Images    
    
sudo apt-get install -y wget apt-transport-https gnupg
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install -y trivy

# Logausgabe ueber mehrere Pods in einem ReplicaSet

wget https://github.com/stern/stern/releases/download/v1.22.0/stern_1.22.0_linux_amd64.tar.gz
tar xvzf stern_1.22.0_linux_amd64.tar.gz
sudo mv stern /usr/local/bin

# Lasttest
wget https://hey-release.s3.us-east-2.amazonaws.com/hey_linux_amd64 -O hey
chmod 755 hey
sudo mv hey /usr/local/bin/

# Wie jq aber verarbeitet auch YAML etc.
sudo apt-get install -y yq
