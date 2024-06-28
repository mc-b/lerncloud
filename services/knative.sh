#!/bin/bash
#
#   Installiert die Erweiterung k-native (Serverless, FAAS) fuer Kubernetes
#

sudo microk8s kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.14.1/serving-crds.yaml
sudo microk8s kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.14.1/serving-core.yaml    
sudo microk8s kubectl apply -f https://github.com/knative/net-kourier/releases/download/knative-v1.14.0/kourier.yaml
sudo microk8s kubectl patch configmap/config-network --namespace knative-serving --type merge --patch '{"data":{"ingress-class":"kourier.ingress.networking.knative.dev"}}'
sudo microk8s kubectl patch configmap/config-domain --namespace knative-serving --type merge --patch '{"data":{"microk8s.mshome.net":""}}'  
sudo curl -o /usr/local/bin/kn -sL https://github.com/knative/client/releases/download/knative-v1.14.0/kn-linux-amd64
sudo chmod +x /usr/local/bin/kn 
