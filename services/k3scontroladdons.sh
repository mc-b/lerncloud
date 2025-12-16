#!/bin/bash
#   
#   Installiert die k3s Add-ons, wie Dashboard etc.
#
set +e  # Fehler ignorieren

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

echo "- 🔧 [INFO] install nginx"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/baremetal/deploy.yaml

kubectl patch ingressclass nginx \
  -p '{"metadata":{"annotations":{"ingressclass.kubernetes.io/is-default-class":"true"}}}'
  
kubectl patch deployment ingress-nginx-controller \
  -n ingress-nginx \
  --type='json' \
  -p='[
    {"op":"add","path":"/spec/template/spec/containers/0/ports/0/hostPort","value":80},
    {"op":"add","path":"/spec/template/spec/containers/0/ports/1/hostPort","value":443}
  ]'
  

echo "- 🔧 [INFO] install dashboard"
kubectl apply -f https://raw.githubusercontent.com/mc-b/lerncloud/master/addons/dashboard.yaml 
kubectl apply -f https://raw.githubusercontent.com/mc-b/lerncloud/master/addons/dashboard-admin.yaml