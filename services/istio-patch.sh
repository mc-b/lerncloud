#!/bin/bash
#   
#   Istio - Patch. Verringert den Memory Bedarf von Istio Sidecars etc.
#
set +e  # Fehler ignorieren

echo "- 🔧 [INFO] Istio CPU und Memory begrenzen"

kubectl get configmap istio-sidecar-injector -n istio-system -o json | \
jq '.data.values |= (
  fromjson
  | .global.proxy.resources = {
      limits: { cpu: "50m", memory: "128Mi" },
      requests: { cpu: "25m", memory: "96Mi" }
    }
  | .global.waypoint.resources = {
      limits: { cpu: "50m", memory: "128Mi" },
      requests: { cpu: "25m", memory: "96Mi" }
    }
  | tojson
)' | kubectl apply -f -

# Kontrolle der Werte
kubectl get configmap istio-sidecar-injector -n istio-system -o json | jq '.data.values | fromjson | .global.proxy.resources, .global.waypoint.resources'

# Istio Services fuer max. 50 Services mit Sidecar

echo "- 🔧 [INFO] Istio Services fuer max. 50 Services mit Sidecar"
  
kubectl patch deployment istiod -n istio-system \
  -p '{"spec":{"template":{"spec":{"containers":[{"name":"discovery","resources":{"limits":{"cpu":"300m","memory":"512Mi"},"requests":{"cpu":"100m","memory":"256Mi"}}}]}}}}'
  
kubectl patch deployment istio-ingressgateway -n istio-system \
  -p '{"spec":{"template":{"spec":{"containers":[{"name":"istio-proxy","resources":{"limits":{"cpu":"150m","memory":"256Mi"},"requests":{"cpu":"50m","memory":"96Mi"}}}]}}}}'

  