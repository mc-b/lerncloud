#!/bin/bash
#   
#   Installiert die Microk8s Add-ons, wie Dashboard, Helm3 etc.
#
set +e  # Fehler ignorieren

echo "- 🔧 [INFO] enable Ingress, Metrics und Dashboard aktivieren"
sudo microk8s enable ingress metrics-server

sudo microk8s kubectl apply -f https://raw.githubusercontent.com/mc-b/lerncloud/master/addons/dashboard.yaml   
