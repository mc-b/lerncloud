#!/bin/bash
#
#   Installiert Argo CD
#
set +e  # Fehler ignorieren

echo "🚀 [INFO] Installing ArgoCD"

kubectl create namespace argocd || echo "Namespace argocd exists"
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "- 🔧 [INFO] Patching ArgoCD server service to LoadBalancer"
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

echo "- ℹ️ [INFO] Waiting for ArgoCD admin secret"
while ! kubectl -n argocd get secret argocd-initial-admin-secret >/dev/null 2>&1; do 
  echo -n "."
  sleep 2
done

echo ""
echo "✅ [INFO] ArgoCD Installation Complete"