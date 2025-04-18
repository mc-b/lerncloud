#!/bin/bash
# 
# Cert Manager

echo "🚀 Starte Cert-Manager Installation..."
sudo microk8s enable cert-manager


echo "- 🔧 Richte eine CA für interne Zertifikate ein."
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-cluster-issuer
spec:
  selfSigned: {}
EOF

echo "🏁 Cert-Manager wurde erfolgreich installiert!"
