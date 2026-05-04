#!/bin/bash
set +e  # Fehler ignorieren

KUBEVIRT_NS="kubevirt"
CDI_NS="cdi"

echo "🚀 [INFO] Starte KubeVirt Installation..."

echo "[INFO] Configure inotify limits for KubeVirt"

sudo tee /etc/sysctl.d/99-kubevirt-inotify.conf >/dev/null <<EOF
fs.inotify.max_user_instances=1024
fs.inotify.max_user_watches=1048576
EOF

sudo sysctl -p /etc/sysctl.d/99-kubevirt-inotify.conf

echo "[INFO] Current inotify limits:"
sysctl fs.inotify.max_user_instances
sysctl fs.inotify.max_user_watches

# Kubernetes-Labels für Master/Control-Plane setzen
echo "- 🔧 [INFO] Kubernetes-Labels für Master/Control-Plane setzen"
kubectl label nodes $(kubectl get nodes -o custom-columns=NAME:.metadata.name | awk 'NR==2') node-role.kubernetes.io/master=
kubectl label nodes $(kubectl get nodes -o custom-columns=NAME:.metadata.name | awk 'NR==2') node-role.kubernetes.io/control-plane=

# Neueste Versionen holen
KUBEVIRT_VERSION=$(curl -s https://api.github.com/repos/kubevirt/kubevirt/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
CDI_VERSION=$(curl -s https://api.github.com/repos/kubevirt/containerized-data-importer/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

# KubeVirt Namespace erstellen, wenn nicht vorhanden
kubectl get ns "$KUBEVIRT_NS" >/dev/null 2>&1 || kubectl create ns "$KUBEVIRT_NS"

# KubeVirt installieren
kubectl apply -f "https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-operator.yaml"
kubectl apply -f "https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-cr.yaml"
kubectl -n "$KUBEVIRT_NS" wait kv kubevirt --for condition=Available --timeout=5m

# Emulation aktivieren (falls VM in VM läuft)
echo "- 🔧 [INFO] Emulation aktivieren"
kubectl -n kubevirt patch kubevirt kubevirt --type=merge --patch '{"spec":{"configuration":{"developerConfiguration":{"useEmulation":true}}}}' 

# virtctl herunterladen
echo "- 📥 [INFO] virtctl herunterladen"
# KubeVirt Version ermitteln
VERSION=$(curl -fsSL https://storage.googleapis.com/kubevirt-prow/release/kubevirt/kubevirt/stable.txt)

# Architektur erkennen
ARCH=$(uname -m)
case "$ARCH" in
  x86_64)
    ARCH="amd64"
    ;;
  aarch64 | arm64)
    ARCH="arm64"
    ;;
  *)
    echo "❌ Nicht unterstützte Architektur: $ARCH"
    exit 1
    ;;
esac

BIN="virtctl-${VERSION}-linux-${ARCH}"
URL="https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/${BIN}"

echo "⬇️  Lade virtctl (${VERSION}) für linux-${ARCH}"
wget -nv "$URL"

chmod +x "$BIN"
sudo mv "$BIN" /usr/local/bin/virtctl
echo "✅ [INFO] KubeVirt wurde erfolgreich installiert!"

echo "🚀 [INFO] Starte Containerized Data Importer (CDI) Installation..."

# CDI Namespace erstellen, wenn nicht vorhanden
kubectl get ns "$CDI_NS" >/dev/null 2>&1 || kubectl create ns "$CDI_NS"

# CDI installieren
kubectl apply -f "https://github.com/kubevirt/containerized-data-importer/releases/download/${CDI_VERSION}/cdi-operator.yaml"
kubectl apply -f "https://github.com/kubevirt/containerized-data-importer/releases/download/${CDI_VERSION}/cdi-cr.yaml"
kubectl -n "$CDI_NS" wait cdi cdi --for condition=Available --timeout=5m

echo "✅ [INFO] Containerized Data Importer (CDI) wurde erfolgreich installiert!"