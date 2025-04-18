#!/bin/bash

echo "- 🔧 CPU und Memory für K-native begrenzen"

for ns in knative-serving knative-eventing; do
  echo "Patching deployments in $ns ..."
  for deploy in $(kubectl get deployments -n $ns -o jsonpath='{.items[*].metadata.name}'); do
    echo "- Patching $deploy"
    kubectl -n $ns patch deployment $deploy --type=json -p='[
      {
        "op": "replace",
        "path": "/spec/template/spec/containers/0/resources",
        "value": {
          "requests": {
            "cpu": "25m",
            "memory": "64Mi"
          },
          "limits": {
            "cpu": "50m",
            "memory": "128Mi"
          }
        }
      }
    ]'
  done
done

kubectl scale deployment --replicas=1 -n knative-serving

kubectl rollout restart deployment -n knative-serving
kubectl rollout restart deployment -n knative-eventing
