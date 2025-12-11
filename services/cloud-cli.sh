#!/bin/bash
#
#   Installiert AWS CLI v2, Azure CLI und Google Cloud CLI (gcloud)
#
set +e  # Fehler ignorieren, aber Hinweise ausgeben

echo "☁️ [INFO] Installing AWS CLI + Azure CLI + Google Cloud CLI"

if [ "$EUID" -ne 0 ]; then
  echo "❌ [ERROR] Dieses Script muss als root ausgeführt werden (sudo)."
  exit 1
fi

# Basis-Infos
if [ -r /etc/os-release ]; then
  . /etc/os-release
  DISTRO="${NAME:-Unknown}"
  CODENAME="${VERSION_CODENAME:-$(lsb_release -cs 2>/dev/null || echo noble)}"
else
  DISTRO="Unknown"
  CODENAME="$(lsb_release -cs 2>/dev/null || echo noble)"
fi

ARCH_DEB="$(dpkg --print-architecture 2>/dev/null || echo amd64)"
ARCH_UNAME="$(uname -m)"

echo "- ℹ️ [INFO] Distribution: ${DISTRO} (${CODENAME}), Architektur: ${ARCH_DEB}/${ARCH_UNAME}"

echo "- 🔄 [INFO] apt update"
apt-get update -y

echo "- 📦 [INFO] Installing prerequisites (curl, gnupg, unzip, ...)"
apt-get install -y \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  apt-transport-https \
  software-properties-common \
  unzip || echo "⚠️ [WARN] Einige Prerequisites konnten nicht installiert werden"

###########################################################
# AWS CLI v2
###########################################################
echo ""
echo "🌩️ [INFO] Installing AWS CLI v2"

if command -v aws >/dev/null 2>&1; then
  echo "- ✅ [INFO] AWS CLI ist bereits installiert (aws gefunden)"
else
  TMP_DIR="$(mktemp -d)"
  AWS_ZIP="${TMP_DIR}/awscliv2.zip"

  if [ "${ARCH_UNAME}" = "x86_64" ]; then
    AWS_URL="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
  elif [ "${ARCH_UNAME}" = "aarch64" ] || [ "${ARCH_UNAME}" = "arm64" ]; then
    AWS_URL="https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip"
  else
    echo "⚠️ [WARN] Unbekannte Architektur (${ARCH_UNAME}), versuche x86_64 Installer"
    AWS_URL="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
  fi

  echo "- ⬇️ [INFO] Downloading AWS CLI from ${AWS_URL}"
  curl -fsSL "${AWS_URL}" -o "${AWS_ZIP}" || echo "⚠️ [WARN] Download der AWS CLI fehlgeschlagen"

  echo "- 📦 [INFO] Unzipping AWS CLI"
  unzip -q "${AWS_ZIP}" -d "${TMP_DIR}" || echo "⚠️ [WARN] Entpacken der AWS CLI fehlgeschlagen"

  echo "- 🛠️ [INFO] Installing AWS CLI to /usr/local/aws-cli"
  "${TMP_DIR}/aws/install" -i /usr/local/aws-cli -b /usr/local/bin || echo "⚠️ [WARN] Installation der AWS CLI fehlgeschlagen"

  rm -rf "${TMP_DIR}"
fi

###########################################################
# Azure CLI
###########################################################
echo ""
echo "🔷 [INFO] Installing Azure CLI"

if command -v az >/dev/null 2>&1; then
  echo "- ✅ [INFO] Azure CLI ist bereits installiert (az gefunden)"
else
  mkdir -p /etc/apt/keyrings

  echo "- 🔑 [INFO] Hinzufügen des Microsoft GPG Keys für Azure CLI"
  curl -sL https://packages.microsoft.com/keys/microsoft.asc \
    | gpg --dearmor \
    | tee /etc/apt/keyrings/microsoft-azure-cli.gpg >/dev/null \
    || echo "⚠️ [WARN] Konnte Azure CLI GPG-Key nicht installieren"

  echo "- 📁 [INFO] Hinzufügen des Azure CLI APT-Repositories"
  cat > /etc/apt/sources.list.d/azure-cli.list <<EOF
deb [arch=${ARCH_DEB} signed-by=/etc/apt/keyrings/microsoft-azure-cli.gpg] https://packages.microsoft.com/repos/azure-cli/ ${CODENAME} main
EOF

  echo "- 🔄 [INFO] apt update (Azure CLI Repo)"
  apt-get update -y
  apt-get install -y azure-cli || echo "⚠️ [WARN] Konnte Azure CLI (azure-cli) nicht installieren"
fi

###########################################################
# Google Cloud CLI (gcloud)
###########################################################

echo ""
echo "🌥️ [INFO] Installing Google Cloud CLI (gcloud)"

if command -v gcloud >/dev/null 2>&1; then
  echo "- ✅ [INFO] Google Cloud CLI ist bereits installiert (gcloud gefunden)"
else
  echo "- 🔑 [INFO] Hinzufügen des Google Cloud GPG Keys"
  curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
    | gpg --dearmor \
    -o /usr/share/keyrings/cloud.google.gpg \
    || echo "⚠️ [WARN] Konnte Google Cloud GPG-Key nicht installieren"

  echo "- 📁 [INFO] Hinzufügen des Google Cloud APT-Repositories"
  cat > /etc/apt/sources.list.d/google-cloud-sdk.list <<EOF
deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main
EOF

  echo "- 🔄 [INFO] apt update (Google Cloud Repo)"
  apt-get update -y
  apt-get install -y google-cloud-cli || echo "⚠️ [WARN] Konnte Google Cloud CLI (google-cloud-cli) nicht installieren"
fi

###########################################################
# Terraform
###########################################################
echo ""
echo "🏗️ [INFO] Installing Terraform"

if command -v terraform >/dev/null 2>&1; then
  echo "- ✅ [INFO] Terraform ist bereits installiert (terraform gefunden)"
else
  mkdir -p /etc/apt/keyrings

  # HashiCorp GPG Key – nur installieren, wenn nicht vorhanden
  if [ ! -f /etc/apt/keyrings/hashicorp-archive-keyring.gpg ]; then
    echo "- 🔑 [INFO] Installing HashiCorp GPG key"
    curl -fsSL https://apt.releases.hashicorp.com/gpg \
      | gpg --dearmor \
      -o /etc/apt/keyrings/hashicorp-archive-keyring.gpg \
      || echo "⚠️ [WARN] Konnte HashiCorp GPG-Key nicht installieren"
  else
    echo "- ℹ️ [INFO] HashiCorp GPG key existiert bereits – überspringe"
  fi

  # Repository einrichten (idempotent)
  echo "- 📁 [INFO] Adding HashiCorp APT repository"
  cat > /etc/apt/sources.list.d/hashicorp.list <<EOF
deb [arch=${ARCH_DEB} signed-by=/etc/apt/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com ${CODENAME} main
EOF

  echo "- 🔄 [INFO] apt update (HashiCorp Repo)"
  apt-get update -y
  apt-get install -y terraform || echo "⚠️ [WARN] Konnte Terraform nicht installieren"
fi

###########################################################
# OpenTofu (Standalone Installer – works on Ubuntu 24.04)
###########################################################

echo ""
echo "🫘 [INFO] Installing OpenTofu (standalone installer – APT repo not available for noble)"

if command -v tofu >/dev/null 2>&1; then
  echo "- ✅ [INFO] OpenTofu ist bereits installiert (tofu gefunden)"
else
  echo "- ⬇️ [INFO] Download & Install OpenTofu standalone"
  curl -fsSL https://get.opentofu.org/install-opentofu.sh \
    | sudo bash -s -- --install-method standalone \
                      --opentofu-version latest \
                      --install-path /opt/opentofu \
                      --symlink-path /usr/local/bin \
    || echo "❌ [ERROR] OpenTofu Installation fehlgeschlagen"
fi


