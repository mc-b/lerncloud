#!/usr/bin/env bash
#
# =============================================================================
# NVIDIA GPU Operator – Installation für k3s und MicroK8s
# =============================================================================
#
# Zweck:
#   Installiert oder aktualisiert den NVIDIA GPU Operator auf einem bestehenden
#   Kubernetes-Cluster mit NVIDIA GPU-Unterstützung.
#
# Voraussetzungen:
#   - Ubuntu mit funktionsfähigen NVIDIA-Treibern (nvidia-smi)
#   - Kubernetes 1.35 bis 1.37 (k3s oder MicroK8s)
#   - Installiertes Helm und kubectl mit Zugriff auf den Zielcluster
#   - containerd mit aktiviertem CDI/NRI
#
# Konfiguration:
#   GPU Operator:       v26.7.2 (über GPU_OPERATOR_VERSION anpassbar)
#   NVIDIA-Treiber:     Bereits auf dem Host installiert
#   Container Toolkit:  Installation durch GPU Operator
#   CDI / NRI:          Aktiviert
#   GPU Time-Slicing:   8 logische GPU-Replikate pro physischer GPU
#   Namespace:          gpu-operator
#
# Funktionen:
#   - Prüft NVIDIA-Treiber und Kubernetes-Version
#   - Erstellt Namespace und Time-Slicing-ConfigMap
#   - Installiert oder aktualisiert den GPU Operator mittels Helm
#   - Aktiviert CDI/NRI und GPU Time-Slicing
#   - Kontrolliert GPU-Ressourcen im Kubernetes-Cluster
#
# Verwendung:
#   curl -sfL https://raw.githubusercontent.com/mc-b/lerncloud/refs/heads/main/services/nvidia-gpu-operator.sh | sh -
#
# =============================================================================
set -Eeuo pipefail

GPU_OPERATOR_VERSION="${GPU_OPERATOR_VERSION:-v26.7.2}"
GPU_REPLICAS="${GPU_REPLICAS:-8}"
NAMESPACE="gpu-operator"
RELEASE="gpu-operator"
CONFIGMAP="time-slicing-config"

log() { echo "[GPU] $*"; }
die() { echo "[ERROR] $*" >&2; exit 1; }

# Voraussetzungen
for cmd in kubectl helm nvidia-smi; do
  command -v "$cmd" >/dev/null 2>&1 ||
    die "Befehl fehlt: $cmd"
done

nvidia-smi -L >/dev/null ||
  die "NVIDIA-Treiber funktioniert nicht."

[[ "$GPU_REPLICAS" =~ ^[1-9][0-9]*$ ]] ||
  die "GPU_REPLICAS muss eine positive Ganzzahl sein."

# Kubernetes-Version prüfen
VERSION_JSON="$(kubectl get --raw /version)" ||
  die "Kubernetes-API nicht erreichbar."

if [[ "$VERSION_JSON" =~ \"gitVersion\"[[:space:]]*:[[:space:]]*\"v([0-9]+)\.([0-9]+) ]]; then
  MAJOR="${BASH_REMATCH[1]}"
  MINOR="${BASH_REMATCH[2]}"
else
  die "Kubernetes-Version nicht ermittelbar."
fi

(( MAJOR == 1 && MINOR >= 35 && MINOR <= 37 )) ||
  die "Unterstützt werden Kubernetes 1.35 bis 1.37."

log "Kubernetes 1.${MINOR} erkannt."

# Direkte, nicht unterstützte Major-Upgrades verhindern
OLD_VERSION="$(
  helm list -n "$NAMESPACE" --filter "^${RELEASE}$" -o json |
    grep -oE '"chart"[[:space:]]*:[[:space:]]*"gpu-operator-v?[0-9]+\.[0-9]+\.[0-9]+"' |
    grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || true
)"

if [[ -n "$OLD_VERSION" &&
      "$OLD_VERSION" != 26.3.* &&
      "$OLD_VERSION" != 26.7.* ]]; then
  die "Zuerst von ${OLD_VERSION} auf v26.3.3 aktualisieren."
fi

# Namespace und GPU Time-Slicing
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: ${NAMESPACE}
  labels:
    pod-security.kubernetes.io/enforce: privileged
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: ${CONFIGMAP}
  namespace: ${NAMESPACE}
data:
  any: |-
    version: v1
    flags:
      migStrategy: none
    sharing:
      timeSlicing:
        resources:
          - name: nvidia.com/gpu
            replicas: ${GPU_REPLICAS}
EOF

# GPU Operator:
# - bestehende Host-Treiber weiterverwenden
# - Toolkit durch Operator verwalten
# - CDI und NRI aktivieren
# - Time-Slicing direkt konfigurieren
log "Installiere GPU Operator ${GPU_OPERATOR_VERSION} ..."

helm upgrade --install "$RELEASE" \
  oci://nvcr.io/nvidia/cloud-native-charts/gpu-operator \
  --namespace "$NAMESPACE" \
  --version "$GPU_OPERATOR_VERSION" \
  --reset-values \
  --disable-openapi-validation \
  --set driver.enabled=false \
  --set toolkit.enabled=true \
  --set cdi.enabled=true \
  --set cdi.nriPluginEnabled=true \
  --set devicePlugin.config.name="$CONFIGMAP" \
  --set devicePlugin.config.default=any \
  --wait --timeout 15m

# Aktualisierte Time-Slicing-ConfigMap übernehmen
if kubectl -n "$NAMESPACE" get \
    daemonset/nvidia-device-plugin-daemonset \
    >/dev/null 2>&1; then
  kubectl -n "$NAMESPACE" rollout restart \
    daemonset/nvidia-device-plugin-daemonset
fi

log "GPU Operator installiert."
kubectl get pods -n "$NAMESPACE"
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{" GPU="}{.status.allocatable.nvidia\.com/gpu}{"\n"}{end}'
