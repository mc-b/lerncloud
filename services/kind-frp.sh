#!/bin/bash
#
# Installiert den FRP (Fast Reverse Proxy) startet ihn als System Daemon
# Erstellt einen K8s kind Cluster mit FRP Client

echo "🚀 [INFO] Starte FRP (Fast Reverse Proxy) und kind (Kubernetes in Docker) Installation..."

# Installation der benoetigten Software
apt-get install -y wget tar docker.io openssl jq
usermod -aG docker ubuntu 

curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Installation frp Server und Erstellung Daemon

echo "- 🚀 [INFO] Starte FRP (Fast Reverse Proxy) Installation..."
export FRP_TOKEN=$(openssl rand -hex 16)

wget -O /tmp/frp.tar.gz https://github.com/fatedier/frp/releases/latest/download/frp_0.61.2_linux_amd64.tar.gz
tar -xzf /tmp/frp.tar.gz -C /opt
mv /opt/frp_*/frps /usr/local/bin/frps
mkdir -p /etc/frp
envsubst <<EOF > /etc/frp/frps.ini
[common]
bind_port = 7000
vhost_http_port = 8000
vhost_https_port = 8443
dashboard_port = 7500
dashboard_user = admin
dashboard_pwd = insecure
token = ${FRP_TOKEN}
EOF

chown root:root /usr/local/bin/frps
chmod +x /usr/local/bin/frps

cat <<EOF > /etc/systemd/system/frps.service
[Unit]
Description=FRP Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/frps -c /etc/frp/frps.ini
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reexec
systemctl daemon-reload
systemctl enable frps
systemctl start frps
  
# kind K8s Cluster  
  
echo "- 🚀 [INFO] Starte kind (Kubernetes in Docker) Installation..."  

curl -Lo kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64 && chmod +x kind && sudo mv ./kind /usr/local/bin/kind

cat <<EOF > /home/ubuntu/kind-config.yaml
# kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    extraMounts:
      - hostPath: /data
        containerPath: /data
    extraPortMappings:
      - containerPort: 80
        hostPort: 80
        protocol: TCP
      - containerPort: 443
        hostPort: 443
        protocol: TCP
  - role: worker
    extraMounts:
      - hostPath: /data
        containerPath: /data
  - role: worker
    extraMounts:
      - hostPath: /data
        containerPath: /data
EOF

su - ubuntu -c "kind create cluster --config kind-config.yaml --name kind --retain"
sleep 2

# Dashboard, Ingress
echo "- 🔧 [INFO] richte /data, Dashboad, Ingress ein"
su - ubuntu -c "kubectl apply -f https://raw.githubusercontent.com/mc-b/lerncloud/master/data/DataVolume.yaml"
su - ubuntu -c "kubectl apply -f https://raw.githubusercontent.com/mc-b/lerncloud/master/addons/dashboard.yaml"
su - ubuntu -c "kubectl apply -f https://raw.githubusercontent.com/mc-b/lerncloud/master/addons/dashboard-admin.yaml"
su - ubuntu -c "kubectl label node kind-control-plane ingress-ready=true kubernetes.io/os=linux"  
su - ubuntu -c "kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.4/deploy/static/provider/kind/deploy.yaml"
su - ubuntu -c "docker ps --filter "name=kind" --format "{{.Names}}" | xargs -n1 docker update --restart unless-stopped"

# frps Client
echo "- 🚀 [INFO] Starte FRP (Fast Reverse Proxy) Client Installation..."
su - ubuntu -c "git clone https://gitlab.com/ch-mc-b/autoshop-ms/infra/gateway.git"
su - ubuntu -c "helm install frp-gateway-operator ./gateway/operator --namespace frp --create-namespace --set frp.token=${FRP_TOKEN} --set frp.host=$(hostname -I | awk '{ print $1 }')"        

echo "✅ [INFO] FRP (Fast Reverse Proxy) und kind (Kubernetes in Docker) ist eingerichtet"
  
