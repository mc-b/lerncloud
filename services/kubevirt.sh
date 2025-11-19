#!/bin/bash
set +e  # Fehler ignorieren

KUBEVIRT_NS="kubevirt"
CDI_NS="cdi"

echo "🚀 [INFO] Starte KubeVirt Installation..."

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
export VERSION=$(curl https://storage.googleapis.com/kubevirt-prow/release/kubevirt/kubevirt/stable.txt)
wget -nv https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/virtctl-${VERSION}-linux-amd64
chmod +x virtctl-${VERSION}-linux-amd64
sudo mv virtctl-${VERSION}-linux-amd64 /usr/local/bin/virtctl

echo "✅ [INFO] KubeVirt wurde erfolgreich installiert!"

echo "🚀 [INFO] Starte Containerized Data Importer (CDI) Installation..."

# CDI Namespace erstellen, wenn nicht vorhanden
kubectl get ns "$CDI_NS" >/dev/null 2>&1 || kubectl create ns "$CDI_NS"

# CDI installieren
kubectl apply -f "https://github.com/kubevirt/containerized-data-importer/releases/download/${CDI_VERSION}/cdi-operator.yaml"
kubectl apply -f "https://github.com/kubevirt/containerized-data-importer/releases/download/${CDI_VERSION}/cdi-cr.yaml"
kubectl -n "$CDI_NS" wait cdi cdi --for condition=Available --timeout=5m

echo "✅ [INFO] Containerized Data Importer (CDI) wurde erfolgreich installiert!"