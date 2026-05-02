#!/usr/bin/env bash
#
#   Installiert OpenTelemetry
#
set -Eeuo pipefail

NAMESPACE="opentelemetry"
RELEASE="opentelemetry-operator"
TRACING_FILE="/tmp/telemetry-$$.yaml"

cleanup() {
  rm -f "${TRACING_FILE}"
}
trap cleanup EXIT

log() {
  echo "$*"
  echo "$*" >>"${TRACING_FILE}"
}

log "🚀 [INFO] Starte OpenTelemetry Installation..."

helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts >>"${TRACING_FILE}" 2>&1
helm repo update >>"${TRACING_FILE}" 2>&1

helm upgrade --install "${RELEASE}" open-telemetry/opentelemetry-operator \
  -n "${NAMESPACE}" \
  --create-namespace \
  --wait \
  --timeout 5m \
  >>"${TRACING_FILE}" 2>&1

log "⏳ [INFO] Warte auf OpenTelemetry CRDs..."

kubectl wait --for=condition=Established crd/opentelemetrycollectors.opentelemetry.io \
  --timeout=120s >>"${TRACING_FILE}" 2>&1

log "⏳ [INFO] Warte auf OpenTelemetry Operator Deployment..."

kubectl -n "${NAMESPACE}" rollout status deployment/opentelemetry-operator-controller-manager \
  --timeout=180s >>"${TRACING_FILE}" 2>&1

log "🔧 [INFO] OpenTelemetry Collector aktivieren..."

kubectl apply -f - <<'EOF' >>"${TRACING_FILE}" 2>&1
apiVersion: opentelemetry.io/v1beta1
kind: OpenTelemetryCollector
metadata:
  name: otel-collector
  namespace: opentelemetry
spec:
  mode: daemonset
  image: otel/opentelemetry-collector-contrib:latest
  config:
    receivers:
      otlp:
        protocols:
          grpc:
            endpoint: 0.0.0.0:4317
          http:
            endpoint: 0.0.0.0:4318

    processors:
      memory_limiter:
        check_interval: 1s
        limit_percentage: 75
        spike_limit_percentage: 15
      batch: {}

    exporters:
      zipkin:
        endpoint: http://zipkin.istio-system.svc.cluster.local:9411/api/v2/spans
      debug: {}

    service:
      pipelines:
        traces:
          receivers: [otlp]
          processors: [memory_limiter, batch]
          exporters: [zipkin, debug]
EOF

kubectl -n "${NAMESPACE}" rollout status daemonset/otel-collector-collector \
  --timeout=180s >>"${TRACING_FILE}" 2>&1 || true

log "✅ [INFO] OpenTelemetry wurde erfolgreich installiert!"
