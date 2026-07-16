#!/bin/bash
#   
#   Installiert die Microk8s Add-ons, wie Dashboard, Helm3 etc.
#
set +e  # Fehler ignorieren

echo "- 🔧 [INFO] enable Ingress, Metrics und Headlamp aktivieren"
sudo microk8s enable ingress
sudo microk8s enable metrics-server

# Headlamp als Alternative zum Dashboard
sudo microk8s kubectl apply -f https://raw.githubusercontent.com/headlamp-k8s/headlamp/main/kubernetes-headlamp.yaml
sudo microk8s kubectl -n kube-system create serviceaccount headlamp-admin
sudo microk8s kubectl create clusterrolebinding headlamp-admin --serviceaccount=kube-system:headlamp-admin --clusterrole=cluster-admin

sudo microk8s kubectl patch svc headlamp \
  -n kube-system \
  --type='merge' \
  -p '{
    "spec": {
      "type": "NodePort",
      "ports": [
        {
          "port": 80,
          "targetPort": 4466,
          "nodePort": 30444
        }
      ]
    }
  }'
