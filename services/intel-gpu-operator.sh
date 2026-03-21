#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Script: install-intel-gpu-plugin.sh
#
# Zweck:
# - Prüfen, ob überhaupt eine Intel GPU vorhanden ist
# - Falls nein: sauber mit exit 0 beenden
# - Intel GPU Userspace / Tools installieren
# - llama.cpp Vulkan Binary installieren
# - Intel Device Plugin for Kubernetes ausrollen
# - DaemonSet für Shared Devices patchen
#
# Wichtige Annahme:
# - Das Script läuft als root
# - kubectl muss aber als Benutzer "ubuntu" ausgeführt werden
# -----------------------------------------------------------------------------

LLAMA_VERSION="b8457"
LLAMA_URL="https://github.com/ggml-org/llama.cpp/releases/download/${LLAMA_VERSION}/llama-${LLAMA_VERSION}-bin-ubuntu-vulkan-x64.tar.gz"
GPU_PLUGIN_NAMESPACE="gpu-plugin"
K8S_USER="ubuntu"
K8S_USER_HOME="/home/${K8S_USER}"
KUBECONFIG_PATH="${K8S_USER_HOME}/.kube/config"

log() {
  echo "[INFO] $*"
}

warn() {
  echo "[WARN] $*" >&2
}

error() {
  echo "[ERROR] $*" >&2
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    error "Befehl nicht gefunden: $1"
    exit 1
  }
}

# -----------------------------------------------------------------------------
# kubectl immer als ubuntu ausführen
# -----------------------------------------------------------------------------
kubectl_u() {
  sudo -u "${K8S_USER}" -H env KUBECONFIG="${KUBECONFIG_PATH}" kubectl "$@"
}

# -----------------------------------------------------------------------------
# Prüfen, ob kubectl für ubuntu funktioniert
# -----------------------------------------------------------------------------
check_kubectl_access() {
  if [ ! -f "${KUBECONFIG_PATH}" ]; then
    error "KUBECONFIG nicht gefunden: ${KUBECONFIG_PATH}"
    exit 1
  fi

  if ! kubectl_u version --client >/dev/null 2>&1; then
    error "kubectl kann als Benutzer ${K8S_USER} nicht gestartet werden."
    exit 1
  fi

  if ! kubectl_u cluster-info >/dev/null 2>&1; then
    error "Cluster ist als Benutzer ${K8S_USER} nicht erreichbar."
    exit 1
  fi
}

# -----------------------------------------------------------------------------
# Prüfen, ob eine Intel GPU vorhanden ist
# -----------------------------------------------------------------------------
has_intel_gpu() {
  if command -v lspci >/dev/null 2>&1; then
    if lspci -nn | grep -qiE 'VGA|3D|Display' && lspci -nn | grep -qi 'Intel'; then
      return 0
    fi

    if lspci -nn | grep -qiE 'Intel.*(VGA|3D|Display)'; then
      return 0
    fi
  fi

  if [ -d /sys/bus/pci/devices ]; then
    for dev in /sys/bus/pci/devices/*; do
      [ -f "$dev/vendor" ] || continue
      [ -f "$dev/class" ] || continue

      vendor="$(cat "$dev/vendor" 2>/dev/null)"
      class="$(cat "$dev/class" 2>/dev/null)"

      if [ "$vendor" = "0x8086" ] && [[ "$class" == 0x03* ]]; then
        return 0
      fi
    done
  fi

  return 1
}

# -----------------------------------------------------------------------------
# Hilfsfunktion: Namespace nur erstellen, wenn er fehlt
# -----------------------------------------------------------------------------
ensure_namespace() {
  local ns="$1"
  if kubectl_u get namespace "$ns" >/dev/null 2>&1; then
    log "Namespace ${ns} existiert bereits."
  else
    log "Erstelle Namespace ${ns} ..."
    kubectl_u create namespace "$ns"
  fi
}

# -----------------------------------------------------------------------------
# Hilfsfunktion: temporäres Verzeichnis
# -----------------------------------------------------------------------------
cleanup() {
  if [ -n "${TMP_DIR:-}" ] && [ -d "${TMP_DIR:-}" ]; then
    rm -rf "${TMP_DIR}"
  fi
}
trap cleanup EXIT

# -----------------------------------------------------------------------------
# Vorbedingungen prüfen
# -----------------------------------------------------------------------------
require_cmd wget
require_cmd kubectl

if ! id "${K8S_USER}" >/dev/null 2>&1; then
  error "Benutzer ${K8S_USER} existiert nicht."
  exit 1
fi

if ! command -v lspci >/dev/null 2>&1; then
  warn "lspci nicht gefunden. Intel GPU-Erkennung nutzt Fallback über /sys."
fi

if ! has_intel_gpu; then
  warn "Keine Intel GPU erkannt. Installation wird übersprungen."
  exit 0
fi

log "Intel GPU erkannt. Fahre mit Installation fort ..."
check_kubectl_access

# -----------------------------------------------------------------------------
# 1) Pakete installieren
# -----------------------------------------------------------------------------
log "Installiere Intel GPU Pakete und Vulkan / VA-API Tools ..."
apt update
apt install -y \
  pciutils \
  intel-media-va-driver \
  vainfo \
  intel-gpu-tools \
  mesa-vulkan-drivers \
  libvulkan1 \
  vulkan-tools \
  mesa-utils

# -----------------------------------------------------------------------------
# 2) Testbefehle ausführen
# -----------------------------------------------------------------------------
log "Führe Basistests aus ..."
vainfo || warn "vainfo lieferte einen Fehler."
ls -l /dev/dri || warn "/dev/dri ist nicht vorhanden."
id "${K8S_USER}" || warn "id ${K8S_USER} konnte nicht ausgeführt werden."
groups "${K8S_USER}" || warn "groups ${K8S_USER} konnte nicht ausgeführt werden."
lspci -nnk | grep -A3 -E 'VGA|3D|Display' || warn "Keine Anzeige über lspci gefunden."

# -----------------------------------------------------------------------------
# 3) llama.cpp Vulkan Binary installieren
# -----------------------------------------------------------------------------
log "Installiere llama.cpp Vulkan Binary (${LLAMA_VERSION}) ..."
TMP_DIR="$(mktemp -d)"
cd "${TMP_DIR}"

wget -O llama.tgz "${LLAMA_URL}" || {
  error "Download von llama.cpp Vulkan Binary fehlgeschlagen."
  exit 1
}

tar xvf llama.tgz

LLAMA_DIR="$(find . -maxdepth 1 -type d -name 'llama-*' | head -n1)"

if [ -z "${LLAMA_DIR}" ]; then
  error "Entpacktes llama.cpp Verzeichnis nicht gefunden."
  exit 1
fi

log "Installiere Dateien aus ${LLAMA_DIR} nach /usr/local/bin ..."
find "${LLAMA_DIR}" -maxdepth 1 -type f -executable -exec mv {} /usr/local/bin/ \;

# -----------------------------------------------------------------------------
# 4) Intel Device Plugin for Kubernetes ausrollen
# -----------------------------------------------------------------------------
log "Installiere Node Feature Discovery ..."
kubectl_u apply -k 'https://github.com/intel/intel-device-plugins-for-kubernetes/deployments/nfd?ref=main'

log "Installiere Node Feature Rules ..."
kubectl_u apply -k 'https://github.com/intel/intel-device-plugins-for-kubernetes/deployments/nfd/overlays/node-feature-rules?ref=main'

ensure_namespace "${GPU_PLUGIN_NAMESPACE}"

log "Installiere Intel GPU Plugin ..."
kubectl_u apply -k 'https://github.com/intel/intel-device-plugins-for-kubernetes/deployments/gpu_plugin/overlays/nfd_labeled_nodes?ref=main' -n "${GPU_PLUGIN_NAMESPACE}"

# -----------------------------------------------------------------------------
# 5) DaemonSet patchen für Shared Devices / Monitoring
# -----------------------------------------------------------------------------
log "Patche DaemonSet intel-gpu-plugin ..."
kubectl_u patch daemonset intel-gpu-plugin \
  -n "${GPU_PLUGIN_NAMESPACE}" \
  --type='json' \
  -p='[
    {
      "op": "replace",
      "path": "/spec/template/spec/containers/0/args",
      "value": [
        "-enable-monitoring",
        "-shared-dev-num=4",
        "-allocation-policy=none",
        "-v=2"
      ]
    }
  ]'

# -----------------------------------------------------------------------------
# 6) Rollout abwarten
# -----------------------------------------------------------------------------
log "Warte auf Rollout des DaemonSets intel-gpu-plugin ..."
kubectl_u rollout status daemonset/intel-gpu-plugin -n "${GPU_PLUGIN_NAMESPACE}"

log "Fertig. Intel GPU Plugin und llama.cpp Vulkan Binary wurden installiert."