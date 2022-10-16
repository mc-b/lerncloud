#!/bin/bash
#   
#   Installiert die Microk8s Add-ons, wie Dashboard, Helm3 etc.
#

sudo microk8s enable ingress metrics-server

sudo microk8s kubectl apply -f https://raw.githubusercontent.com/mc-b/lerncloud/master/addons/dashboard.yaml   
