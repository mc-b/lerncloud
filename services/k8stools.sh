#!/bin/bash
set -e

#
#   Nützliche Tools rund um Kubernetes
#

echo "🔍 [INFO] Architektur erkennen …"

ARCH_RAW=$(uname -m)
case "$ARCH_RAW" in
  x86_64)
    ARCH="amd64"
    GOARCH="amd64"
    ;;
  aarch64|arm64)
    ARCH="arm64"
    GOARCH="arm64"
    ;;
  *)
    echo "❌ [ERROR] Nicht unterstützte Architektur: $ARCH_RAW"
    exit 1
    ;;
esac

echo "✅ [INFO] Erkannte Architektur: $ARCH_RAW → $ARCH"

TMPDIR="/tmp/k8s-tools"
mkdir -p "$TMPDIR"
cd "$TMPDIR"

# ------------------------------------------------------------
# kube-lineage
# ------------------------------------------------------------
echo "📥 [INFO] Tools: kube-lineage herunterladen"
wget -nv "https://github.com/tohjustin/kube-lineage/releases/download/v0.5.0/kube-lineage_linux_${ARCH}.tar.gz"
tar xzf "kube-lineage_linux_${ARCH}.tar.gz"
sudo mv kube-lineage /usr/local/bin/
rm "kube-lineage_linux_${ARCH}.tar.gz"

# ------------------------------------------------------------
# kompose
# ------------------------------------------------------------
echo "📥 [INFO] docker-compose to K8s: kompose herunterladen"
curl -L "https://github.com/kubernetes/kompose/releases/download/v1.37.0/kompose-linux-${ARCH}" -o kompose
chmod +x kompose
sudo mv kompose /usr/local/bin/

# ------------------------------------------------------------
# kind
# ------------------------------------------------------------
echo "📥 [INFO] K8s in Docker: kind herunterladen"
curl -Lo kind "https://kind.sigs.k8s.io/dl/v0.30.0/kind-linux-${ARCH}"
chmod +x kind
sudo mv kind /usr/local/bin/

# ------------------------------------------------------------
# trivy
# ------------------------------------------------------------
echo "📥 [INFO] Security: trivy installieren"
sudo apt-get install -y wget apt-transport-https gnupg
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key \
  | gpg --dearmor \
  | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null

echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" \
  | sudo tee /etc/apt/sources.list.d/trivy.list

sudo apt-get update
sudo apt-get install -y trivy

# ------------------------------------------------------------
# kubescape
# ------------------------------------------------------------
echo "📥 [INFO] Security: kubescape herunterladen"
curl -s https://raw.githubusercontent.com/kubescape/kubescape/master/install.sh | /bin/bash

# ------------------------------------------------------------
# hey
# ------------------------------------------------------------
echo "📥 [INFO] Lasttests: hey herunterladen"
wget -nv "https://hey-release.s3.us-east-2.amazonaws.com/hey_linux_${ARCH}" -O hey
chmod 755 hey
sudo mv hey /usr/local/bin/

# ------------------------------------------------------------
# yq
# ------------------------------------------------------------
echo "📥 [INFO] Tools: yq installieren"
sudo apt-get install -y yq

# ------------------------------------------------------------
# skaffold
# ------------------------------------------------------------
echo "📥 [INFO] CI/CD: skaffold herunterladen"
curl -Lo skaffold "https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-${ARCH}"
chmod +x skaffold
sudo mv skaffold /usr/local/bin/

# ------------------------------------------------------------
# k9s
# ------------------------------------------------------------
echo "📥 [INFO] UI: k9s installieren"
sudo snap install k9s --classic
sudo ln -sf /snap/k9s/current/bin/k9s /snap/bin/k9s

echo "🎉 [DONE] Alle Tools erfolgreich installiert für ${ARCH}"
