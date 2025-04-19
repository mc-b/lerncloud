#!/bin/bash
# 
# Cert Manager

echo "🚀 [INFO] Starte Cert-Manager Installation..."
sudo microk8s enable cert-manager


echo "- 🔧 [INFO] Richte eine CA für interne Zertifikate ein."
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-cluster-issuer
spec:
  selfSigned: {}
EOF

echo "✅ [INFO] Cert-Manager wurde erfolgreich installiert!"
