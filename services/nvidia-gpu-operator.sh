#!/usr/bin/env bash
set +e  # Fehler ignorieren

# -----------------------------------------------------------------------------
# Script: install-gpu-operator-timeslicing.sh
#
# Zweck:
# - NVIDIA Container Toolkit installieren
# - NVIDIA Helm Repository hinzufügen
# - GPU Operator installieren
# - ConfigMap für GPU Time-Slicing anlegen
# - GPU Operator erneut mit Time-Slicing-Konfiguration ausrollen
#
# Annahmen:
# - helm ist bereits installiert
# - kubectl ist bereits installiert und funktionsfähig
# - der Benutzer "ubuntu" existiert
# - der aktuelle Cluster-Kontext zeigt auf den Ziel-Cluster
# -----------------------------------------------------------------------------

# Konfigurierbare Variablen
GPU_OPERATOR_VERSION="v25.10.1"
GPU_OPERATOR_NAMESPACE="gpu-operator"
HELM_REPO_NAME="nvidia"
HELM_REPO_URL="https://helm.ngc.nvidia.com/nvidia"
TIMESLICING_CONFIGMAP_NAME="time-slicing-config"
TIMESLICING_PROFILE_NAME="any"
GPU_REPLICAS="8"

# -----------------------------------------------------------------------------
# Hilfsfunktion für Log-Ausgaben
# -----------------------------------------------------------------------------
log() {
  echo "[INFO] $*"
}

# -----------------------------------------------------------------------------
# Prüfen, ob notwendige Befehle vorhanden sind
# -----------------------------------------------------------------------------
require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "[ERROR] Befehl nicht gefunden: $1" >&2
    exit 1
  }
}

require_cmd apt-get
require_cmd helm
require_cmd kubectl
require_cmd sudo

# -----------------------------------------------------------------------------
# 1) NVIDIA Container Toolkit installieren
# -----------------------------------------------------------------------------
log "Installiere nvidia-container-toolkit ..."
sudo apt-get update
sudo apt-get install -y --no-install-recommends ca-certificates curl gnupg2

curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
  sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit nvidia-utils-570

# -----------------------------------------------------------------------------
# 2) Helm Repository als Benutzer ubuntu hinzufügen/aktualisieren
#
# Hintergrund:
# Helm speichert Repos standardmässig im Home-Verzeichnis des aufrufenden Users.
# Daher wird dieser Schritt explizit als Benutzer 'ubuntu' ausgeführt.
# -----------------------------------------------------------------------------
log "Füge NVIDIA Helm Repository hinzu und aktualisiere es ..."
sudo -u ubuntu -H bash -lc "
  set -euo pipefail
  helm repo add ${HELM_REPO_NAME} ${HELM_REPO_URL} 2>/dev/null || true
  helm repo update
"

# -----------------------------------------------------------------------------
# 3) GPU Operator zunächst installieren
#
# driver.enabled=false:
#   Treiber werden nicht durch den Operator installiert
#
# toolkit.enabled=false:
#   Container Toolkit wird nicht durch den Operator installiert
#   (weil es oben bereits via apt installiert wurde)
# -----------------------------------------------------------------------------
log "Installiere GPU Operator ohne Treiber und ohne Toolkit ..."
sudo -u ubuntu -H bash -lc "
  set -euo pipefail
  helm upgrade --install gpu-operator ${HELM_REPO_NAME}/gpu-operator \
    --wait \
    --version=${GPU_OPERATOR_VERSION} \
    --namespace ${GPU_OPERATOR_NAMESPACE} \
    --create-namespace \
    --set driver.enabled=false \
    --set toolkit.enabled=false
"

# -----------------------------------------------------------------------------
# 4) ConfigMap für GPU Time-Slicing anlegen/aktualisieren
#
# Diese ConfigMap teilt pro physischer GPU 16 logische Zeitscheiben-Replikate aus.
# Das ist nützlich, wenn mehrere Workloads dieselbe GPU zeitlich geteilt nutzen.
# -----------------------------------------------------------------------------
log "Erstelle/Aktualisiere ConfigMap für GPU Time-Slicing ..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: ${TIMESLICING_CONFIGMAP_NAME}
  namespace: ${GPU_OPERATOR_NAMESPACE}
data:
  ${TIMESLICING_PROFILE_NAME}: |-
    version: v1
    flags:
      migStrategy: none
    sharing:
      timeSlicing:
        resources:
          - name: nvidia.com/gpu
            replicas: ${GPU_REPLICAS}
EOF

# -----------------------------------------------------------------------------
# 5) GPU Operator erneut ausrollen, diesmal mit referenzierter Time-Slicing Config
#
# devicePlugin.config.name:
#   Name der ConfigMap
#
# devicePlugin.config.default:
#   Schlüssel innerhalb der ConfigMap, der als Default-Profil verwendet wird
# -----------------------------------------------------------------------------
log "Rolle GPU Operator mit aktivierter Time-Slicing-Konfiguration erneut aus ..."
sudo -u ubuntu -H bash -lc "
  set -euo pipefail
  helm upgrade --install gpu-operator ${HELM_REPO_NAME}/gpu-operator \
    --wait \
    --version=${GPU_OPERATOR_VERSION} \
    --namespace ${GPU_OPERATOR_NAMESPACE} \
    --create-namespace \
    --set driver.enabled=false \
    --set toolkit.enabled=false \
    --set devicePlugin.config.name=${TIMESLICING_CONFIGMAP_NAME} \
    --set devicePlugin.config.default=${TIMESLICING_PROFILE_NAME}
"

log "Fertig. GPU Operator und Time-Slicing-Konfiguration wurden angewendet."
