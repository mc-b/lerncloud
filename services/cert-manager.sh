#!/bin/bash

echo "🚀 [INFO] Starte Cert-Manager Installation..."

# kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.20.2/cert-manager.yaml

helm repo add jetstack https://charts.jetstack.io --force-update
helm install \
    cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --create-namespace \
    --version "v1.20.2" \
    --set crds.enabled=true \
    --wait

echo "- ⏳ Warte auf cert-manager CRDs..."
kubectl wait --for=condition=Established crd/certificates.cert-manager.io --timeout=240s
kubectl wait --for=condition=Established crd/issuers.cert-manager.io --timeout=240s
kubectl wait --for=condition=Established crd/clusterissuers.cert-manager.io --timeout=240s

echo "- ⏳ Warte auf cert-manager Deployments..."
kubectl -n cert-manager rollout status deploy/cert-manager --timeout=240s
kubectl -n cert-manager rollout status deploy/cert-manager-cainjector --timeout=240s
kubectl -n cert-manager rollout status deploy/cert-manager-webhook --timeout=240s

echo "- ⏳ Warte auf cert-manager API..."
kubectl wait --for=condition=Available apiservice/v1.cert-manager.io --timeout=240s

echo "- 🔧 [INFO] Richte SelfSigned ClusterIssuer ein"
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-cluster-issuer
spec:
  selfSigned: {}
EOF

kubectl wait --for=condition=Ready clusterissuer/selfsigned-cluster-issuer --timeout=120s

echo "- 🔧 [INFO] Erzeuge Root CA"
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: root-ca
  namespace: cert-manager
spec:
  isCA: true
  commonName: Local CA
  secretName: root-ca-secret
  issuerRef:
    name: selfsigned-cluster-issuer
    kind: ClusterIssuer
EOF

kubectl -n cert-manager wait --for=condition=Ready certificate/root-ca --timeout=120s

echo "- 🔧 [INFO] Richte CA ClusterIssuer ein"
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: root-ca-issuer
spec:
  ca:
    secretName: root-ca-secret
EOF

kubectl wait --for=condition=Ready clusterissuer/root-ca-issuer --timeout=120s

if [ -f /home/ubuntu/data/server-ip ]; then
  echo "- 🔧 [INFO] Richte Zertifikat für Server-Adresse ein"

  SERVER_NAME="$(cat /home/ubuntu/data/server-ip)"

  if echo "$SERVER_NAME" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'; then
    kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: root-selfsigned-cert
  namespace: default
spec:
  secretName: root-selfsigned-cert
  duration: 2160h
  renewBefore: 360h
  commonName: ${SERVER_NAME}
  ipAddresses:
    - ${SERVER_NAME}
  issuerRef:
    name: root-ca-issuer
    kind: ClusterIssuer
EOF
  else
    kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: root-selfsigned-cert
  namespace: default
spec:
  secretName: root-selfsigned-cert
  duration: 2160h
  renewBefore: 360h
  commonName: ${SERVER_NAME}
  dnsNames:
    - ${SERVER_NAME}
  issuerRef:
    name: root-ca-issuer
    kind: ClusterIssuer
EOF
  fi

  kubectl -n default wait --for=condition=Ready certificate/root-selfsigned-cert --timeout=120s
fi

echo "✅ [INFO] Cert-Manager wurde erfolgreich installiert!"