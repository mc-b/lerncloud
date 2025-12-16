#!/bin/bash
#   
#   Installiert Rancher k3s Control Node! ohne Ingress Controller traefik - dafuer nginx (zu Schulungszwecken)
#   als root starten
#
set +e  # Fehler ignorieren

echo "🚀 [INFO] Starte k3s Installation..."
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --cluster-init --disable traefik --disable servicelb" sh -

mkdir -p /home/ubuntu/.kube
cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config
chown -R ubuntu:ubuntu /home/ubuntu/.kube
chmod 644 /etc/rancher/k3s/k3s.yaml

snap install helm --classic 
sudo snap install kubectl --classic

###
# Add-ons  
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# Persistente Datenablage (fix)
echo "- 🔧 [INFO] Persistente Dateiablage /data einrichten"
kubectl apply -f https://raw.githubusercontent.com/mc-b/lerncloud/master/data/DataVolume.yaml

echo "✅ [INFO] k3s wurde erfolgreich installiert!"