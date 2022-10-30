#!/bin/bash
#   
#   Installiert Istio (inkl. Addons)
#

export ISTIO_VERSION=1.13.4

curl -L https://istio.io/downloadIstio | sh -
sudo cp istio-${ISTIO_VERSION}/bin/istioctl /usr/local/bin/
istioctl install -y --set profile=demo

# Addons

kubectl apply -f istio-${ISTIO_VERSION}/samples/addons
kubectl rollout status deployment/kiali -n istio-system

# Pull Limits HACK!

sudo apt-get install -y docker.io
for image in prom/prometheus:v2.31.1 jimmidyson/configmap-reload:v0.5.0 cdkbot/hostpath-provisioner:1.4.1 docker.io/jaegertracing/all-in-one:1.29
do
    NEW=public.ecr.aws/f6h1p2z9/docker.io:$(echo ${image} | tr ':' 'S' | tr '/' '_')
    sudo docker pull ${NEW}
    sudo docker tag ${NEW} ${image}
    sudo docker save -o tmp.tar ${image}
    microk8s ctr image import tmp.tar
done
rm tmp.tar