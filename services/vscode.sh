#!/bin/bash
#
#   Installiert Visual Studio Code
#
set +e  # Fehler ignorieren, aber Hinweise ausgeben

echo "🧩 [INFO] Installing Visual Studio Code"

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

echo "- ℹ️ [INFO] Distribution: ${DISTRO} (${CODENAME}), Architektur: ${ARCH_DEB}"

echo "- 🔄 [INFO] apt update"
apt-get update -y

echo "- 📦 [INFO] Installing prerequisites (curl, gnupg, ...)"
apt-get install -y \
  ca-certificates \
  curl \
  gnupg \
  apt-transport-https \
  software-properties-common \
  lsb-release || echo "⚠️ [WARN] Einige Prerequisites konnten nicht installiert werden"

if command -v code >/dev/null 2>&1; then
  echo "✅ [INFO] VS Code ist bereits installiert (code gefunden)"
  exit 0
fi

mkdir -p /etc/apt/keyrings

echo "- 🔑 [INFO] Hinzufügen des Microsoft GPG Keys für VS Code"
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
  | gpg --dearmor \
  -o /etc/apt/keyrings/microsoft-vscode.gpg \
  || echo "⚠️ [WARN] Konnte VS Code GPG-Key nicht installieren"

echo "- 📁 [INFO] Hinzufügen des VS Code APT-Repositories"
cat > /etc/apt/sources.list.d/vscode.list <<EOF
deb [arch=${ARCH_DEB} signed-by=/etc/apt/keyrings/microsoft-vscode.gpg] https://packages.microsoft.com/repos/code stable main
EOF

echo "- 🔄 [INFO] apt update (VS Code Repo)"
apt-get update -y

echo "- 📦 [INFO] Installing VS Code (code)"
apt-get install -y code || echo "⚠️ [WARN] Konnte VS Code (code) nicht installieren"

echo ""
echo "✅ [INFO] VS Code Installation abgeschlossen:"
echo "   - VS Code (code): $(command -v code >/dev/null 2>&1 && echo 'OK' || echo 'NICHT gefunden')"
