#!/bin/bash
# 
# Cert Manager

echo "🚀 [INFO] Starte Cert-Manager Installation..."
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.17.0/cert-manager.yaml
kubectl wait --namespace cert-manager --for=condition=Ready pods --all --timeout=240s

# Wait for the webhook configuration to exist
echo "- ⏳ Waiting for cert-manager webhook configuration to appear..."
until kubectl get mutatingwebhookconfiguration cert-manager-webhook > /dev/null 2>&1; do
  sleep 2
done

echo "- ✅ Webhook configuration exists."

# Wait until caBundle is injected by cainjector
echo -n "- ⏳ Waiting for CA Bundle to be injected into webhook..."
until [ "$(kubectl get mutatingwebhookconfiguration cert-manager-webhook -o jsonpath='{.webhooks[0].clientConfig.caBundle}')" != "" ]; do
  echo "."
  sleep 5
done
echo ""

echo "- ✅ CA Bundle injected successfully!"

echo "- 🔧 [INFO] Richte SelfSigned ClusterIssuer (stellt die CA aus) ein"
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-cluster-issuer
spec:
  selfSigned: {}
EOF

echo "- 🔧 [INFO] Richte Certificate für CA ein"
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: root-ca
  namespace: cert-manager  # Wichtig: im cert-manager-namespace!
spec:
  isCA: true
  commonName: Local CA
  secretName: root-ca-secret
  issuerRef:
    name: selfsigned-cluster-issuer
    kind: ClusterIssuer
EOF

echo "- 🔧 [INFO] Richte CA Issuer (nutzt die erzeugte CA) ein"
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: root-ca-issuer
spec:
  ca:
    secretName: root-ca-secret
EOF
    
if  [ -f ~/data/server-ip ]
then
    echo "- 🔧 [INFO] Richte das eigentliches Zertifikat ein"
    kubectl apply -f - <<EOF    
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: root-selfsigned-cert
  namespace: default  # oder wo deine App läuft
spec:
  secretName: root-selfsigned-cert
  duration: 2160h # 90 Tage
  renewBefore: 360h # 15 Tage
  commonName: $(cat ~/data/server-ip)
  dnsNames:
    - $(cat ~/data/server-ip)
  issuerRef:
    name: root-ca-issuer
    kind: ClusterIssuer
EOF
fi

echo "✅ [INFO] Cert-Manager wurde erfolgreich installiert!"
