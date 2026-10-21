#!/usr/bin/env bash
# =============================================================================
# Intel GPU Device Plugin – Installation für k3s und MicroK8s
# =============================================================================
# Zweck:
#   Installiert Intel GPU Firmware/Userspace unter Ubuntu und das Intel GPU
#   Device Plugin inkl. Node Feature Discovery (NFD) in Kubernetes.
#
# Voraussetzungen:
#   - Ubuntu 24.04 mit Intel GPU und passendem Kernel (i915 oder xe)
#   - Kubernetes 1.35 bis 1.37 (k3s oder MicroK8s)
#   - kubectl mit Zugriff auf den Zielcluster
#   - Benutzer mit passwortlosem sudo (z.B. via cloud-init/runuser)
#   - Homogener Kubelet-Geräteplugin-Pfad auf den GPU-Nodes des Clusters
#
# Konfiguration:
#   INTEL_PLUGIN_VERSION=v0.37.0  (Version der Intel-Deployments)
#   GPU_SHARED_DEV_NUM=4         (logische Zuweisungen pro GPU)
#   KUBELET_WAIT_SECONDS=120     (maximale Wartezeit auf Kubelet-Socket)
#   Namespace: gpu-plugin
#
# Verwendung:
#   ./intel-gpu-operator.sh
#   GPU_SHARED_DEV_NUM=8 ./intel-gpu-operator.sh
#
# Hinweise:
#   - Kernelmodule i915/xe kommen vom Kernel, nicht aus diesem Script.
#   - Falls die GPU noch keine /dev/dri/renderD*-Datei hat, ist der Kernel-/
#     Firmware-Support zu prüfen (ggf. Kernelupgrade/Neustart notwendig).
#   - Intel GPU Libraries müssen auch im jeweiligen Workload-Image vorhanden sein.
#   - GPU-Sharing ist keine VRAM- oder GPU-Isolation.
# =============================================================================
set -Eeuo pipefail

INTEL_PLUGIN_VERSION="${INTEL_PLUGIN_VERSION:-v0.37.0}"
GPU_SHARED_DEV_NUM="${GPU_SHARED_DEV_NUM:-4}"
KUBELET_WAIT_SECONDS="${KUBELET_WAIT_SECONDS:-120}"
GPU_PLUGIN_NAMESPACE="gpu-plugin"

log() { printf '[Intel GPU] %s\n' "$*"; }
die() { printf '[ERROR] %s\n' "$*" >&2; exit 1; }

# PCI Vendor ID 8086 + Klasse 03xx: keine falschen Treffer durch Intel NICs/CPUs.
has_intel_gpu() {
  local dev vendor class
  for dev in /sys/bus/pci/devices/*; do
    [[ -r "$dev/vendor" && -r "$dev/class" ]] || continue
    read -r vendor < "$dev/vendor"
    read -r class < "$dev/class"
    [[ "$vendor" == 0x8086 && "$class" == 0x03* ]] && return 0
  done
  return 1
}

has_intel_gpu || { log 'Keine Intel GPU erkannt; Installation übersprungen.'; exit 0; }

for cmd in sudo kubectl; do
  command -v "$cmd" >/dev/null 2>&1 || die "Befehl nicht gefunden: $cmd"
done
sudo -n true || die 'Passwortloses sudo wird für die Host-Pakete benötigt.'
[[ "$GPU_SHARED_DEV_NUM" =~ ^[1-9][0-9]*$ ]] || die 'GPU_SHARED_DEV_NUM muss positiv und ganzzahlig sein.'
[[ "$KUBELET_WAIT_SECONDS" =~ ^[0-9]+$ ]] || die 'KUBELET_WAIT_SECONDS muss eine nichtnegative Ganzzahl sein.'

# K8s-Zugriff und Version prüfen.
VERSION_JSON="$(kubectl get --raw /version)" || die 'Kubernetes-API nicht erreichbar.'
if [[ "$VERSION_JSON" =~ \"gitVersion\"[[:space:]]*:[[:space:]]*\"v([0-9]+)\.([0-9]+) ]]; then
  MAJOR="${BASH_REMATCH[1]}"
  MINOR="${BASH_REMATCH[2]}"
else
  die 'Kubernetes-Version nicht ermittelbar.'
fi
(( MAJOR == 1 && MINOR >= 35 && MINOR <= 37 )) || die "Kubernetes $MAJOR.$MINOR nicht unterstützt (erwartet 1.35–1.37)."
log "Kubernetes $MAJOR.$MINOR erkannt."

# Ubuntu bringt die Intel-Kerneltreiber i915/xe mit. Die folgenden Pakete
# liefern Firmware und Userspace für VA-API, OpenCL und Vulkan.
log 'Installiere Intel GPU Firmware und Userspace-Pakete ...'
sudo apt-get update
sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  linux-firmware \
  git \
  intel-media-va-driver \
  intel-opencl-icd \
  intel-gpu-tools \
  mesa-vulkan-drivers \
  libvulkan1 \
  vulkan-tools \
  vainfo \
  clinfo

# Auf dem GPU-Host muss ein render-Device vorhanden sein.
if ! compgen -G '/dev/dri/renderD*' >/dev/null; then
  die 'Kein /dev/dri/renderD* vorhanden: Kernel-/Firmware-Unterstützung (i915/xe) prüfen und ggf. neu starten.'
fi

# Das Skript läuft als ubuntu. Die Kubelet-Verzeichnisse sind ggf. nur für
# root lesbar; daher den Socket ausdrücklich mit sudo prüfen.
# Während cloud-init kann der Kubelet noch starten: kurz auf den Socket warten.
# Die Reihenfolge bevorzugt den Kubernetes-Standardpfad.
KUBELET_DEVICE_PLUGIN_DIR=''
for ((second=0; second<=KUBELET_WAIT_SECONDS; second+=5)); do
  for dir in \
    /var/lib/kubelet/device-plugins \
    /var/lib/rancher/k3s/agent/kubelet/device-plugins \
    /var/snap/microk8s/common/var/lib/kubelet/device-plugins; do
    if sudo -n test -S "$dir/kubelet.sock"; then
      KUBELET_DEVICE_PLUGIN_DIR="$dir"
      break 2
    fi
  done
  (( second < KUBELET_WAIT_SECONDS )) && sleep 5
done
if [[ -z "$KUBELET_DEVICE_PLUGIN_DIR" ]]; then
  log 'Keinen Kubelet-Socket gefunden. Gefundene Socket-Pfade:'
  sudo -n find \
    /var/lib/kubelet \
    /var/lib/rancher/k3s/agent/kubelet \
    /var/snap/microk8s/common/var/lib/kubelet \
    -name kubelet.sock -type s -print 2>/dev/null || true
  die 'Kubelet-Socket fehlt auch nach der Wartezeit. Kubelet-/K3s-/MicroK8s-Dienst kontrollieren.'
fi
log "Kubelet-Device-Plugin-Verzeichnis: $KUBELET_DEVICE_PLUGIN_DIR"

# Intel veröffentlicht gepinnte Kustomize-Deployments je Release.
REPO='https://github.com/intel/intel-device-plugins-for-kubernetes'
TAG="${INTEL_PLUGIN_VERSION}"
log "Installiere NFD und Intel GPU Plugin $TAG ..."
kubectl apply -k "${REPO}/deployments/nfd?ref=${TAG}"
kubectl apply -k "${REPO}/deployments/nfd/overlays/node-feature-rules?ref=${TAG}"
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: ${GPU_PLUGIN_NAMESPACE}
  labels:
    pod-security.kubernetes.io/enforce: privileged
    pod-security.kubernetes.io/audit: privileged
    pod-security.kubernetes.io/warn: privileged
EOF
kubectl apply -k "${REPO}/deployments/gpu_plugin/overlays/nfd_labeled_nodes?ref=${TAG}" \
  --namespace "$GPU_PLUGIN_NAMESPACE"

# GPU-Sharing aktivieren. Die Standard-Kubelet-Mounts bleiben unverändert.
log "Aktiviere GPU-Sharing (${GPU_SHARED_DEV_NUM}) ..."
kubectl -n "$GPU_PLUGIN_NAMESPACE" patch daemonset intel-gpu-plugin \
  --type=strategic -p "$(cat <<EOF
{
  "spec": {
    "template": {
      "spec": {
        "containers": [{
          "name": "intel-gpu-plugin",
          "args": [
            "-enable-monitoring",
            "-shared-dev-num=${GPU_SHARED_DEV_NUM}",
            "-allocation-policy=none",
            "-v=2"
          ]
        }]
      }
    }
  }
}
EOF
)"

# Nur wenn kubelet ausserhalb des Standardpfads arbeitet, den bestehenden
# Volume-Mount des Device Plugins auf das gefundene Host-Verzeichnis ändern.
# Dabei wird der Volume-Name aus dem Deployment ermittelt (keine Annahme).
if [[ "$KUBELET_DEVICE_PLUGIN_DIR" != /var/lib/kubelet/device-plugins ]]; then
  VOLUME_NAME="$(
    kubectl -n "$GPU_PLUGIN_NAMESPACE" get daemonset intel-gpu-plugin \
      -o jsonpath='{range .spec.template.spec.volumes[*]}{.name}{"\t"}{.hostPath.path}{"\n"}{end}' |
      awk '$2 ~ /device-plugins$/ {print $1; exit}'
  )"
  [[ -n "$VOLUME_NAME" ]] || die 'Kubelet-Device-Plugin-Volume im DaemonSet nicht gefunden.'
  log "Passe Volume ${VOLUME_NAME} an: ${KUBELET_DEVICE_PLUGIN_DIR}"
  kubectl -n "$GPU_PLUGIN_NAMESPACE" patch daemonset intel-gpu-plugin \
    --type=strategic -p "$(cat <<EOF
{
  "spec": {
    "template": {
      "spec": {
        "volumes": [{
          "name": "${VOLUME_NAME}",
          "hostPath": {
            "path": "${KUBELET_DEVICE_PLUGIN_DIR}",
            "type": "Directory"
          }
        }]
      }
    }
  }
}
EOF
)"
fi

log 'Warte auf die GPU-Registrierung in Kubernetes ...'
for ((attempt=1; attempt<=60; attempt++)); do
  GPU_RESOURCES="$(kubectl get nodes -o jsonpath='{range .items[*]}{.status.allocatable.gpu\.intel\.com/i915}{" "}{.status.allocatable.gpu\.intel\.com/xe}{"\n"}{end}')"
  if grep -Eq '[1-9][0-9]*' <<< "$GPU_RESOURCES"; then
    kubectl -n "$GPU_PLUGIN_NAMESPACE" rollout status daemonset/intel-gpu-plugin --timeout=2m
    kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{" i915="}{.status.allocatable.gpu\.intel\.com/i915}{" xe="}{.status.allocatable.gpu\.intel\.com/xe}{"\n"}{end}'
    log 'Intel GPU Device Plugin eingerichtet.'
    exit 0
  fi
  sleep 5
done

die 'GPU nicht in Kubernetes registriert. NFD-Labels, Device-Plugin-Logs und Kubelet-Socket prüfen.'
