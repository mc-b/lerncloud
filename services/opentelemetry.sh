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

log "🔐 [INFO] OpenTelemetry Collector ServiceAccount/RBAC einrichten..."

RBAC_FILE="/tmp/otel-rbac-$$.yaml"

cat >"${RBAC_FILE}" <<'EOF'
apiVersion: v1
apiVersion: v1
kind: ServiceAccount
metadata:
  name: otel-collector
  namespace: opentelemetry
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: otel-collector-k8sattributes
rules:
  - apiGroups: [""]
    resources: ["pods", "namespaces", "nodes"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["apps"]
    resources: ["replicasets", "deployments", "daemonsets", "statefulsets"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: otel-collector-k8sattributes
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: otel-collector-k8sattributes
subjects:
  - kind: ServiceAccount
    name: otel-collector
    namespace: opentelemetry
EOF

retry 20 10 kubectl apply -f "${RBAC_FILE}"

log "🔐 [INFO] OpenTelemetry Observability Stack (Prometheus, Grafana, Jaeger) einrichten..."

STACK_FILE="/tmp/otel-stack-$$.yaml"

cat >"${STACK_FILE}" <<'EOF'
helm upgrade --install my-otel-demo open-telemetry/opentelemetry-demo \
  -n opentelemetry \
  -f - <<'EOF'
components:
  accounting: { enabled: false }
  ad: { enabled: false }
  cart: { enabled: false }
  checkout: { enabled: false }
  currency: { enabled: false }
  email: { enabled: false }
  fraud-detection: { enabled: false }
  frontend: { enabled: false }
  image-provider: { enabled: false }
  load-generator: { enabled: false }
  payment: { enabled: false }
  product-catalog: { enabled: false }
  product-reviews: { enabled: false }
  quote: { enabled: false }
  recommendation: { enabled: false }
  shipping: { enabled: false }
  kafka: { enabled: false }
  llm: { enabled: false }
  postgresql: { enabled: false }
  valkey-cart: { enabled: false }

  flagd:
    enabled: true

  frontend-proxy:
    enabled: true
    envOverrides:
      - name: OTEL_COLLECTOR_NAME
        value: otel-collector-collector

default:
  envOverrides:
    - name: OTEL_COLLECTOR_NAME
      value: otel-collector-collector

opentelemetry-collector:
  enabled: false

opensearch:
  enabled: false

jaeger:
  enabled: true
  fullnameOverride: jaeger

prometheus:
  enabled: true
  server:
    fullnameOverride: prometheus
    extraFlags:
      - web.enable-otlp-receiver
      - enable-feature=exemplar-storage
    extraScrapeConfigs: |
      - job_name: kubernetes-pods-ms-otel
        kubernetes_sd_configs:
          - role: pod
            namespaces:
              names:
                - ms-otel
        relabel_configs:
          - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
            action: keep
            regex: "true"
          - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
            action: replace
            target_label: __metrics_path__
            regex: "(.+)"
          - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
            action: replace
            target_label: __address__
            regex: "([^:]+)(?::\\d+)?;(\\d+)"
            replacement: "$1:$2"
          - source_labels: [__meta_kubernetes_namespace]
            action: replace
            target_label: namespace
          - source_labels: [__meta_kubernetes_pod_name]
            action: replace
            target_label: pod

      - job_name: otel-collector
        static_configs:
          - targets:
              - otel-collector-collector.opentelemetry.svc.cluster.local:8888

grafana:
  enabled: true
  fullnameOverride: grafana
  adminPassword: admin
  grafana.ini:
    auth:
      disable_login_form: true
    auth.anonymous:
      enabled: true
      org_role: Admin
    server:
      root_url: "%(protocol)s://%(domain)s:%(http_port)s/grafana"
      serve_from_sub_path: true
  sidecar:
    dashboards:
      enabled: true
    datasources:
      enabled: true
EOF

retry 20 10 kubectl apply -f "${RBAC_FILE}"

log "🔧 [INFO] OpenTelemetry Collector aktivieren..."

COLLECTOR_FILE="/tmp/otel-collector-$$.yaml"

cat >"${COLLECTOR_FILE}" <<'EOF'
apiVersion: opentelemetry.io/v1beta1
kind: OpenTelemetryCollector
metadata:
  name: otel-collector
  namespace: opentelemetry
spec:
  mode: deployment
  serviceAccount: otel-collector
  image: otel/opentelemetry-collector-contrib:latest
  ports:
    - name: otlp-grpc
      port: 4317
      targetPort: 4317
      protocol: TCP
    - name: otlp-http
      port: 4318
      targetPort: 4318
      protocol: TCP
    - name: metrics
      port: 8888
      targetPort: 8888
      protocol: TCP
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
        check_interval: 5s
        limit_percentage: 80
        spike_limit_percentage: 25
      k8sattributes:
        auth_type: serviceAccount
        extract:
          metadata:
            - k8s.namespace.name
            - k8s.pod.name
            - k8s.deployment.name
            - k8s.node.name
      batch: {}

    exporters:
      otlp/jaeger:
        endpoint: jaeger.opentelemetry.svc.cluster.local:4317
        tls:
          insecure: true

      otlphttp/prometheus:
        endpoint: http://prometheus.opentelemetry.svc.cluster.local:9090/api/v1/otlp
        tls:
          insecure: true

      debug:
        verbosity: basic

    service:
      telemetry:
        metrics:
          readers:
            - pull:
                exporter:
                  prometheus:
                    host: 0.0.0.0
                    port: 8888
      pipelines:
        traces:
          receivers: [otlp]
          processors: [memory_limiter, k8sattributes, batch]
          exporters: [otlp/jaeger, debug]
        metrics:
          receivers: [otlp]
          processors: [memory_limiter, k8sattributes, batch]
          exporters: [otlphttp/prometheus, debug]
EOF

retry 20 10 kubectl apply -f "${COLLECTOR_FILE}"

log "⏳ [INFO] Warte auf Collector-DaemonSet..."

retry 30 5 kubectl -n "${NAMESPACE}" rollout status daemonset/otel-collector-collector \
  --timeout=30s

log "🔧 [INFO] Zipkin installieren..."

curl -sfL https://raw.githubusercontent.com/istio/istio/release-1.29/samples/addons/extras/zipkin.yaml \
| sed 's/namespace: istio-system/namespace: opentelemetry/g' \
| kubectl apply -f -

log "✅ [INFO] OpenTelemetry wurde erfolgreich installiert!"
