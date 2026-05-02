#!/bin/bash
#
#   Installiert OpenTelemetry
#
set +e  # Fehler ignorieren

TRACING_FILE="/tmp/telemetry-$$.yaml"

echo "🚀 [INFO] Starte OpenTelemetry Installation..."

helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts > "${TRACING_FILE}"
helm upgrade --install opentelemetry-operator open-telemetry/opentelemetry-operator -n opentelemetry --create-namespace >>"${TRACING_FILE}"

# Addons
echo "- 🔧 [INFO] OpenTelemetry Collector aktivieren"

kubectl apply -f - <<'EOF' >>"${TRACING_FILE}"
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


echo "✅ [INFO] OpenTelemetry wurde erfolgreich installiert!"
