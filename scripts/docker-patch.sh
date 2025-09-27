#!/bin/bash
#
#   Einloggen um Rate Limit bei Docker zu erhoehen
#

for ns in $(microk8s kubectl get ns --no-headers -o custom-columns=":metadata.name"); do
  microk8s kubectl create secret docker-registry regcred \
    --docker-server=ghcr.io \
    --docker-username=misegr \
    --docker-password='...' \
    --namespace $ns
done

for ns in $(microk8s kubectl get ns --no-headers -o custom-columns=":metadata.name"); do
  microk8s kubectl patch serviceaccount default \
    -p '{"imagePullSecrets":[{"name":"regcred"}]}' \
    -n $ns
done
