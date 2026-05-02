#!/usr/bin/env bash
#
#   Installiert OpenTelemetry
#
set -Eeuo pipefail

NAMESPACE="opentelemetry"
RELEASE="opentelemetry-operator"
TRACING_FILE="/tmp/telemetry-$$.yaml"

: >"${TRACING_FILE}"

log() {
  echo "$*"
  echo "$*" >>"${TRACING_FILE}"
}

run() {
  echo "+ $*" >>"${TRACING_FILE}"
  "$@" >>"${TRACING_FILE}" 2>&1
}

retry() {
  local tries="$1"
  local sleep_seconds="$2"
  shift 2

  local i
  for i in $(seq 1 "${tries}"); do
    if "$@" >>"${TRACING_FILE}" 2>&1; then
      return 0
    fi

    log "⚠️ [WARN] Versuch ${i}/${tries} fehlgeschlagen: $*"

    if [ "${i}" -lt "${tries}" ]; then
      sleep "${sleep_seconds}"
    fi
  done

  return 1
}

log "🚀 [INFO] Starte OpenTelemetry Installation..."
log "📄 [INFO] Trace-Datei: ${TRACING_FILE}"

run helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
run helm repo update

run helm upgrade --install "${RELEASE}" open-telemetry/opentelemetry-operator \
  -n "${NAMESPACE}" \
  --create-namespace \
  --wait \
  --timeout 10m

log "⏳ [INFO] Warte auf OpenTelemetry CRD..."

retry 30 5 kubectl wait \
  --for=condition=Established \
  crd/opentelemetrycollectors.opentelemetry.io \
  --timeout=20s

log "⏳ [INFO] Warte auf Kubernetes API-Discovery für OpenTelemetryCollector..."

retry 30 5 kubectl api-resources \
  --api-group=opentelemetry.io

log "⏳ [INFO] Warte auf Operator-Pods..."

retry 30 5 kubectl -n "${NAMESPACE}" wait pod \
  -l app.kubernetes.io/name=opentelemetry-operator \
  --for=condition=Ready \
  --timeout=30s

log "⏳ [INFO] Warte auf irgendeinen OpenTelemetry-Webhook EndpointSlice..."

retry 30 5 bash -c '
  kubectl -n "'"${NAMESPACE}"'" get endpointslice \
    -o jsonpath="{range .items[?(@.metadata.labels.app\.kubernetes\.io/instance==\"'"${RELEASE}"'\")]}{.endpoints[*].addresses[*]}{\"\n\"}{end}" | grep -q .
'

log "🔧 [INFO] OpenTelemetry Collector aktivieren..."

retry 20 10 kubectl apply -f - <<'EOF'
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

log "⏳ [INFO] Warte auf Collector-DaemonSet..."

retry 30 5 kubectl -n "${NAMESPACE}" rollout status daemonset/otel-collector-collector \
  --timeout=30s

log "✅ [INFO] OpenTelemetry wurde erfolgreich installiert!"
