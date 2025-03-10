#!/bin/bash
#   
#   Installiert Istio (inkl. Addons)
#

# gibt Probleme mit Jaeger
# export ISTIO_VERSION=1.24.2
#export ISTIO_VERSION=1.13.4
export ISTIO_VERSION=1.21.0

curl -L https://istio.io/downloadIstio | sh -
sudo cp istio-${ISTIO_VERSION}/bin/istioctl /usr/local/bin/
istioctl install -y --set profile=demo

# Addons

kubectl apply -f istio-${ISTIO_VERSION}/samples/addons
kubectl rollout status deployment/kiali -n istio-system
