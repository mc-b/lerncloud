#!/bin/bash
#   
#   Installiert Rancher k3s Control Node! ohne Ingress Controller traefik - dafuer nginx (zu Schulungszwecken)
#   als root starten
#
set +e  # Fehler ignorieren

echo "🚀 [INFO] Starte k3s Installation..."
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --cluster-init --disable traefik --disable servicelb" sh -

mkdir -p /home/ubuntu/.kube
ln -s /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config

echo "- 🔧 [INFO] kubectl und helm einrichten"
sudo ln -sf /usr/local/bin/k3s /usr/local/bin/kubectl
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

###
# Add-ons  
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# Persistente Datenablage (fix)
echo "- 🔧 [INFO] Persistente Dateiablage /data einrichten"
kubectl apply -f https://raw.githubusercontent.com/mc-b/lerncloud/master/data/DataVolume.yaml

echo "✅ [INFO] k3s wurde erfolgreich installiert!"