#!/bin/bash
#
#   Installiert LM Studio / llmster inkl. systemd User-Service
#   als User ubuntu starten
#
set -Eeuo pipefail

LMS_USER="ubuntu"
LMS_HOME="/home/${LMS_USER}"
LMS_BIN="${LMS_HOME}/.lmstudio/bin/lms"

LMS_PORT="1234"
LMS_BIND="0.0.0.0"

# GPU-Offload:
# Gültig: off, max oder Zahl zwischen 0.0 und 1.0
# Für CPU-only:
LMS_GPU="off"
#LMS_GPU="max"

LMS_CONTEXT_LENGTH="4096"

USER_SYSTEMD_DIR="${LMS_HOME}/.config/systemd/user"
USER_SERVICE_FILE="${USER_SYSTEMD_DIR}/lmstudio.service"
START_SCRIPT="${LMS_HOME}/.lmstudio-start.sh"
STOP_SCRIPT="${LMS_HOME}/.lmstudio-stop.sh"

UBUNTU_UID="$(id -u ${LMS_USER})"
XDG_RUNTIME_DIR="/run/user/${UBUNTU_UID}"

LMS_ENV_PATH="${LMS_HOME}/.lmstudio/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

echo "📦 [INFO] Installiere System-Abhängigkeiten..."

sudo apt-get update
sudo apt-get install -y \
  curl \
  ca-certificates \
  libatomic1 \
  libgomp1

echo "🧹 [INFO] Entferne alten System-Service, falls vorhanden..."

sudo systemctl disable --now lmstudio.service >/dev/null 2>&1 || true
sudo rm -f /etc/systemd/system/lmstudio.service
sudo systemctl daemon-reload
sudo systemctl reset-failed lmstudio.service >/dev/null 2>&1 || true

echo "🛑 [INFO] Stoppe vorhandene LM Studio Prozesse, falls aktiv..."

if [ -x "${LMS_BIN}" ]; then
  sudo -u "${LMS_USER}" env HOME="${LMS_HOME}" PATH="${LMS_ENV_PATH}" \
    "${LMS_BIN}" server stop || true

  sudo -u "${LMS_USER}" env HOME="${LMS_HOME}" PATH="${LMS_ENV_PATH}" \
    "${LMS_BIN}" daemon down || true
fi

sudo pkill -u "${LMS_USER}" -f llmster || true
sudo pkill -u "${LMS_USER}" -f ".lmstudio.*node" || true
sleep 3

echo "🚀 [INFO] Installiere LM Studio / llmster..."

sudo -u "${LMS_USER}" env HOME="${LMS_HOME}" bash -lc '
  curl -fsSL https://lmstudio.ai/install.sh | bash
'

echo "🔎 [INFO] Prüfe lms CLI..."

if [ ! -x "${LMS_BIN}" ]; then
  echo "❌ [ERROR] lms CLI wurde nicht gefunden unter ${LMS_BIN}"
  exit 1
fi

sudo -u "${LMS_USER}" env HOME="${LMS_HOME}" PATH="${LMS_ENV_PATH}" \
  "${LMS_BIN}" --version || true

echo "📝 [INFO] Erstelle Startscript..."

sudo tee "${START_SCRIPT}" >/dev/null <<EOF
#!/bin/bash
set -Eeuo pipefail

export HOME="${LMS_HOME}"
export PATH="${LMS_ENV_PATH}"

LMS_BIN="${LMS_BIN}"
LMS_PORT="${LMS_PORT}"
LMS_BIND="${LMS_BIND}"

echo "[INFO] Starte LM Studio Daemon..."

"\${LMS_BIN}" daemon up || true

echo "[INFO] Warte auf Daemon..."

for i in {1..60}; do
  if "\${LMS_BIN}" daemon status >/dev/null 2>&1; then
    echo "[INFO] LM Studio Daemon ist bereit."
    break
  fi

  if [ "\$i" -eq 60 ]; then
    echo "[ERROR] LM Studio Daemon wurde nicht bereit."
    "\${LMS_BIN}" daemon status || true
    exit 1
  fi

  sleep 2
done

echo "[INFO] Stoppe alten Server, falls aktiv..."

"\${LMS_BIN}" server stop || true
sleep 2

echo "[INFO] Starte LM Studio API Server auf \${LMS_BIND}:\${LMS_PORT}..."

"\${LMS_BIN}" server start --port "\${LMS_PORT}" --bind "\${LMS_BIND}"

echo "[INFO] Warte auf API..."

for i in {1..60}; do
  if curl -fsS "http://127.0.0.1:\${LMS_PORT}/v1/models" >/dev/null 2>&1; then
    echo "[INFO] LM Studio API ist bereit."
    exit 0
  fi

  sleep 2
done

echo "[ERROR] LM Studio API wurde nicht bereit."
"\${LMS_BIN}" server status || true
exit 1
EOF

sudo chown "${LMS_USER}:${LMS_USER}" "${START_SCRIPT}"
sudo chmod +x "${START_SCRIPT}"

echo "📝 [INFO] Erstelle Stopscript..."

sudo tee "${STOP_SCRIPT}" >/dev/null <<EOF
#!/bin/bash
set +e

export HOME="${LMS_HOME}"
export PATH="${LMS_ENV_PATH}"

LMS_BIN="${LMS_BIN}"

echo "[INFO] Stoppe LM Studio Server..."

"\${LMS_BIN}" server stop || true

sleep 2

echo "[INFO] Stoppe LM Studio Daemon..."

"\${LMS_BIN}" daemon down || true

exit 0
EOF

sudo chown "${LMS_USER}:${LMS_USER}" "${STOP_SCRIPT}"
sudo chmod +x "${STOP_SCRIPT}"

echo "📝 [INFO] Erstelle systemd User-Service..."

sudo -u "${LMS_USER}" mkdir -p "${USER_SYSTEMD_DIR}"

sudo -u "${LMS_USER}" tee "${USER_SERVICE_FILE}" >/dev/null <<EOF
[Unit]
Description=LM Studio / llmster User API Server
After=default.target

[Service]
Type=oneshot
RemainAfterExit=yes

ExecStart=${START_SCRIPT}
ExecStop=${STOP_SCRIPT}

TimeoutStartSec=300
TimeoutStopSec=90

[Install]
WantedBy=default.target
EOF

echo "🔐 [INFO] Aktiviere linger für User ${LMS_USER}..."

sudo loginctl enable-linger "${LMS_USER}"

echo "🔄 [INFO] Lade systemd User-Service neu..."

sudo -u "${LMS_USER}" XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR}" \
  systemctl --user daemon-reload

echo "✅ [INFO] Aktiviere lmstudio.service als User-Service..."

sudo -u "${LMS_USER}" XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR}" \
  systemctl --user enable lmstudio.service

echo "🚀 [INFO] Starte lmstudio.service als User-Service..."

sudo -u "${LMS_USER}" XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR}" \
  systemctl --user restart lmstudio.service

echo "⏳ [INFO] Warte bis LM Studio API bereit ist..."

for i in {1..60}; do
  if curl -fsS "http://127.0.0.1:${LMS_PORT}/v1/models" >/dev/null 2>&1; then
    echo "✅ [INFO] LM Studio API ist bereit."
    break
  fi

  if [ "$i" -eq 60 ]; then
    echo "❌ [ERROR] LM Studio API wurde nicht rechtzeitig bereit."

    sudo -u "${LMS_USER}" XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR}" \
      systemctl --user status lmstudio.service --no-pager || true

    sudo -u "${LMS_USER}" XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR}" \
      journalctl --user -u lmstudio.service --no-pager -n 100 || true

    exit 1
  fi

  sleep 2
done

echo "📋 [INFO] Status lmstudio.service:"

sudo -u "${LMS_USER}" XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR}" \
  systemctl --user status lmstudio.service --no-pager || true

echo "📦 [INFO] Optionaler Modell-Download..."

${LMS_BIN} get -y https://huggingface.co/Qwen/Qwen3-Embedding-4B-GGUF 
${LMS_BIN} load -y text-embedding-qwen3-embedding-4b 

#${LMS_BIN} get -y https://huggingface.co/Qwen/Qwen3-Embedding-8B-GGUF 
#${LMS_BIN} load -y text-embedding-qwen3-embedding-8b 

echo ""
echo "✅ [INFO] LM Studio / llmster wurde erfolgreich installiert!"
echo ""
echo "API:"
echo "  http://127.0.0.1:${LMS_PORT}/v1"
echo ""
echo "Modelle:"
curl -fsS "http://127.0.0.1:${LMS_PORT}/v1/models" || true
echo ""
