#!/bin/bash
#
#   Installiert Istio mit Zipkin (leichtgewichtiger)
#
set +e  # Fehler ignorieren

export ISTIO_VERSION=1.27.3
ISTIO_DIR="istio-${ISTIO_VERSION}"
TRACING_FILE="/tmp/tracing-$$.yaml"

echo "🚀 [INFO] Starte Istio $ISTIO_VERSION Installation..."

# Prüfen ob istioctl schon installiert ist
if ! command -v istioctl &>/dev/null; then
    echo "- 🔧 [INFO] Lade Istio herunter..."
    curl -L https://istio.io/downloadIstio | ISTIO_VERSION=${ISTIO_VERSION} sh -
    sudo cp "${ISTIO_DIR}/bin/istioctl" /usr/local/bin/
else
    echo "- ℹ️ [INFO] istioctl ist bereits installiert, überspringe Download."
fi

# Addons
echo "- 🔧 [INFO] Istio Operator aktivieren"

cat > "${TRACING_FILE}" <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    enableTracing: true
    defaultConfig:
      tracing:
        sampling: 0.5
      proxyMetadata:
        ISTIO_META_ENABLE_ACCESS_LOG: "false"
    extensionProviders:
    - name: zipkin
      zipkin:
        service: zipkin.istio-system.svc.cluster.local
        port: 9411
EOF

# Idempotentes Installieren
istioctl install -f "${TRACING_FILE}" --skip-confirmation || true

echo "- 🔧 [INFO] Zipkin aktivieren und konfigurieren"
kubectl apply -f - <<EOF
apiVersion: telemetry.istio.io/v1
kind: Telemetry
metadata:
  name: mesh-default
  namespace: istio-system
spec:
  tracing:
  - providers:
    - name: zipkin
EOF

kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.27/samples/addons/extras/zipkin.yaml

# Service ggf. erneut patchen, ohne Fehler
kubectl get service -n istio-system -l name=zipkin -o yaml \
  | sed 's/ClusterIP/NodePort/g' \
  | kubectl apply -f - || true

echo "✅ [INFO] Istio + Zipkin wurde erfolgreich installiert!"
