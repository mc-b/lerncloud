#!/bin/bash
#   
#   Installiert Istio mit Zipkin (leichtgewichtiger)
#

# gibt Probleme mit Jaeger
export ISTIO_VERSION=1.24.2 

curl -L https://istio.io/downloadIstio | sh -
sudo cp istio-${ISTIO_VERSION}/bin/istioctl /usr/local/bin/

# Addons

cat <<EOF > ./tracing.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    enableTracing: true
    defaultConfig:
      tracing:
        sampling: 0.1  # Nur 10% aller Anfragen werden getraced
      proxyMetadata:
        ISTIO_META_ENABLE_ACCESS_LOG: "false"  # Deaktiviert Access-Logs (optional)        
    extensionProviders:
    - name: zipkin
      zipkin:
        service: zipkin.istio-system.svc.cluster.local
        port: 9411
EOF
istioctl install -f ./tracing.yaml --skip-confirmation

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

kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.24/samples/addons/extras/zipkin.yaml
kubectl get service -n istio-system -l name=zipkin -o yaml | sed 's/ClusterIP/NodePort/g' | kubectl apply -f -