#!/bin/bash
#
#	Kubernetes Add-ons Installation
#

# Dashboard und User einrichten - Zugriff via kubectl proxy und Token mittels kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep kubernetes-dashboard | awk ' { print $1 }') Ermitteln
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.4/aio/deploy/recommended.yaml
kubectl apply -f https://raw.githubusercontent.com/mc-b/lernkube/master/addons/dashboard-admin.yaml

# Metrics Server fuer Dashboard, Horizontal Pods Autoscaler etc.
kubectl create namespace metrics
helm install metrics-server stable/metrics-server --namespace metrics --set args={"--kubelet-insecure-tls=true,--kubelet-preferred-address-types=InternalIP\,Hostname\,ExternalIP"}

# Install ingress bare metal, https://kubernetes.github.io/ingress-nginx/deploy/
kubectl apply -f https://raw.githubusercontent.com/mc-b/lernkube/master/addons/ingress-mandatory.yaml
kubectl apply -f https://raw.githubusercontent.com/mc-b/lernkube/master/addons/service-nodeport.yaml

# Weave Scope 
kubectl apply -f 'https://cloud.weave.works/k8s/scope.yaml?k8s-version='$(kubectl version | base64 | tr -d '\n')
