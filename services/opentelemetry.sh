#!/usr/bin/env bash
#
# Installiert OpenTelemetry, kube-prometheus-stack und Jaeger
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

log " [INFO] Starte OpenTelemetry Installation..."
log " [INFO] Trace-Datei: ${TRACING_FILE}"

run helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
run helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
run helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
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
kubectl -n opentelemetry get endpointslice \
  -o jsonpath="{range .items[?(@.metadata.labels.app\.kubernetes\.io/instance==\"opentelemetry-operator\")]}{.endpoints[*].addresses[*]}{\"\n\"}{end}" | grep -q .
'

log " [INFO] OpenTelemetry Collector ServiceAccount/RBAC einrichten..."

kubectl apply -f - <<'EOF'
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

log " [INFO] kube-prometheus-stack installieren..."

helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  -n "${NAMESPACE}" \
  --wait \
  --timeout 15m \
  -f - <<'EOF'
fullnameOverride: prometheus

defaultRules:
  create: true

grafana:
  enabled: true
  adminPassword: admin
    
  service:
    type: NodePort
    port: 80

  persistence:
    enabled: false

  grafana.ini:
    auth:
      disable_login_form: true
    auth.anonymous:
      enabled: true
      org_role: Admin
      
  sidecar:
    dashboards:
      enabled: false
    datasources:
      enabled: false
    alerts:
      enabled: false
    plugins:
      enabled: false      

  additionalDataSources:
    - name: Jaeger
      uid: jaeger
      type: jaeger
      access: proxy
      url: http://jaeger.opentelemetry.svc.cluster.local:16686

kube-state-metrics:
  enabled: true

prometheus-node-exporter:
  enabled: true

alertmanager:
  enabled: true

  service:
    type: NodePort
    port: 9093

  alertmanagerSpec:
    storage: {}

prometheus:
  enabled: true

  service:
    type: NodePort
    port: 9090

  prometheusSpec:
    enableOTLPReceiver: true
    enableFeatures:
      - exemplar-storage

    retention: 15d
    
    storageSpec: null

    additionalScrapeConfigs:
      - job_name: otel-collector
        static_configs:
          - targets:
              - otel-collector-collector.opentelemetry.svc.cluster.local:8888

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
EOF

log " [INFO] Jaeger installieren..."

helm upgrade --install jaeger jaegertracing/jaeger \
  -n "${NAMESPACE}" \
  --wait \
  --timeout 10m \
  -f - <<'EOF'
fullnameOverride: jaeger

jaeger:
  service:
    type: NodePort
EOF

log " [INFO] OpenTelemetry Collector aktivieren..."

kubectl apply -f - <<'EOF'
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
        endpoint: http://prometheus-prometheus.opentelemetry.svc.cluster.local:9090/api/v1/otlp/v1/metrics
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

log "⏳ [INFO] Warte auf Collector-Deployment..."
retry 30 5 kubectl -n "${NAMESPACE}" rollout status deployment/otel-collector-collector \
  --timeout=30s

log "⏳ [INFO] Warte auf Prometheus..."
retry 30 5 bash -c '
kubectl -n opentelemetry rollout status statefulset/prometheus-prometheus --timeout=30s ||
kubectl -n opentelemetry wait pod -l app.kubernetes.io/name=prometheus --for=condition=Ready --timeout=30s
'

log "⏳ [INFO] Warte auf Alertmanager..."
retry 30 5 bash -c '
kubectl -n opentelemetry rollout status statefulset/alertmanager-prometheus-alertmanager --timeout=30s ||
kubectl -n opentelemetry wait pod -l app.kubernetes.io/name=alertmanager --for=condition=Ready --timeout=30s
'

log "⏳ [INFO] Warte auf Grafana..."
retry 30 5 kubectl -n "${NAMESPACE}" rollout status deployment/prometheus-grafana \
  --timeout=30s

log "⏳ [INFO] Warte auf Jaeger..."
retry 30 5 bash -c '
kubectl -n opentelemetry rollout status deployment/jaeger --timeout=30s ||
kubectl -n opentelemetry wait pod -l app.kubernetes.io/instance=jaeger --for=condition=Ready --timeout=30s
'

log " [INFO] Zugriff via NodePort:"

SERVER_IP="$(cat ~/data/server-ip 2>/dev/null || true)"

if [ -n "${SERVER_IP}" ]; then
  PROMETHEUS_PORT="$(kubectl -n "${NAMESPACE}" get svc prometheus-prometheus -o=jsonpath='{.spec.ports[?(@.port==9090)].nodePort}')"
  ALERTMANAGER_PORT="$(kubectl -n "${NAMESPACE}" get svc prometheus-alertmanager -o=jsonpath='{.spec.ports[?(@.port==9093)].nodePort}')"
  GRAFANA_PORT="$(kubectl -n "${NAMESPACE}" get svc prometheus-grafana -o=jsonpath='{.spec.ports[?(@.port==80)].nodePort}')"
  JAEGER_PORT="$(kubectl -n "${NAMESPACE}" get svc jaeger -o=jsonpath='{.spec.ports[?(@.port==16686)].nodePort}')"

  log "Prometheus UI   : http://${SERVER_IP}:${PROMETHEUS_PORT}"
  log "Alertmanager UI : http://${SERVER_IP}:${ALERTMANAGER_PORT}"
  log "Grafana UI      : http://${SERVER_IP}:${GRAFANA_PORT}"
  log "Jaeger UI       : http://${SERVER_IP}:${JAEGER_PORT}"
else
  log "⚠️ [WARN] ~/data/server-ip nicht gefunden; NodePort-URLs nicht ausgegeben."
fi

log "✅ [INFO] OpenTelemetry wurde erfolgreich installiert!"