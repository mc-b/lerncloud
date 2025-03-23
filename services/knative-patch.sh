#!/bin/bash

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
            "cpu": "100m",
            "memory": "64Mi"
          },
          "limits": {
            "cpu": "300m",
            "memory": "128Mi"
          }
        }
      }
    ]'
  done
done
