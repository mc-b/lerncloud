#!/bin/bash
#
#   Nuetzliche Tools rund um Kubernetes
#

# Hierarchische Anzeige von Deployments, ReplicatSet und Pods

echo "📥 [INFO] Tools: kube-lineage herunterladen"
cd /tmp && wget -nv https://github.com/tohjustin/kube-lineage/releases/download/v0.5.0/kube-lineage_linux_amd64.tar.gz && \
    tar xzf kube-lineage_linux_amd64.tar.gz && \
    sudo mv kube-lineage /usr/local/bin/ && \
    rm kube-lineage_linux_amd64.tar.gz 
    
# docker-compose nach Kubernetes
    
echo "📥 [INFO] docker-compose to K8s: kompose herunterladen"   
curl -L https://github.com/kubernetes/kompose/releases/download/v1.37.0/kompose-linux-amd64 -o kompose && \
    chmod +x kompose && \
    sudo mv ./kompose /usr/local/bin/kompose    

echo "📥 [INFO] K8s in Docker: kind herunterladen"    
# K8s Cluster als Docker Container erstellen    
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.30.0/kind-linux-amd64 && \
    chmod +x kind && \
    sudo mv ./kind /usr/local/bin/kind 
    
# Schwachstellenscanner fuer Container Images    
    
echo "📥 [INFO] Security: trivy + kubescape herunterladen"    
sudo apt-get install -y wget apt-transport-https gnupg
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install -y trivy

# Comprehensive Kubernetes Security from Development to Runtime
curl -sL https://github.com/kubescape/kubescape/releases/latest/download/kubescape-ubuntu-latest -o kubescape
chmod +x kubescape
sudo mv kubescape /usr/local/bin/

# Logausgabe ueber mehrere Pods in einem ReplicaSet

echo "📥 [INFO] Logs: stern herunterladen" 
wget -nv https://github.com/stern/stern/releases/download/v1.22.0/stern_1.22.0_linux_amd64.tar.gz
tar xvzf stern_1.22.0_linux_amd64.tar.gz
sudo mv stern /usr/local/bin

# Lasttest
echo "📥 [INFO] Lasttests: hey herunterladen" 
wget -nv https://hey-release.s3.us-east-2.amazonaws.com/hey_linux_amd64 -O hey
chmod 755 hey
sudo mv hey /usr/local/bin/

# Wie jq aber verarbeitet auch YAML etc.
sudo apt-get install -y yq

# Skaffold - Container Image bauen und deployen
curl -Lo skaffold https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64 && \
sudo install skaffold /usr/local/bin/

# stress-ng - a tool to load and stress a computer system
echo "📥 [INFO] Lasttests: stress herunterladen" 
sudo apt-get install -y stress-ng

# k9s ASCII UI
echo "📥 [INFO] UI: k9s herunterladen" 
sudo snap install k9s --classic
sudo ln -s /snap/k9s/current/bin/k9s /snap/bin/

