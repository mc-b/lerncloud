#!/bin/bash
#   
#   Installiert die k3s Add-ons, wie Dashboard etc.
#
set +e  # Fehler ignorieren

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

echo "- 🔧 [INFO] install nginx"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/baremetal/deploy.yaml

echo "- 🔧 [INFO] install dashboard"
kubectl apply -f https://raw.githubusercontent.com/mc-b/lerncloud/master/addons/dashboard.yaml 
kubectl apply -f https://raw.githubusercontent.com/mc-b/lerncloud/master/addons/dashboard-admin.yaml