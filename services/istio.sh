#!/bin/bash
#   
#   Installiert Istio (inkl. Addons Kiali, Jaeger, Prometheus, Grafana)
#

# gibt Probleme mit Jaeger
export ISTIO_VERSION=1.21.0

curl -L https://istio.io/downloadIstio | sh -
sudo cp istio-${ISTIO_VERSION}/bin/istioctl /usr/local/bin/
istioctl install -y --set profile=demo

# Addons

kubectl apply -f istio-${ISTIO_VERSION}/samples/addons
kubectl rollout status deployment/kiali -n istio-system

# Ports oeffnen

kubectl get service -n istio-system -l app=kiali  -o yaml | sed 's/ClusterIP/NodePort/g' | kubectl apply -f -
kubectl get service -n istio-system -l app=jaeger -o yaml | sed 's/ClusterIP/NodePort/g' | kubectl apply -f -
kubectl get service -n istio-system -l app.kubernetes.io/name=prometheus -o yaml | sed 's/ClusterIP/NodePort/g' | kubectl apply -f -
kubectl get service -n istio-system -l app.kubernetes.io/instance=grafana -o yaml | sed 's/ClusterIP/NodePort/g' | kubectl apply -f -
