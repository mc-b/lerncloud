#!/bin/bash
#   
#   Installiert lokale Inferenzserver und LLMs
#   als User ubuntu starten
#
set +e  # Fehler ignorieren

echo "🚀 [INFO] Installiere Ollama..."

curl -fsSL https://ollama.com/install.sh | sh  
sudo mkdir -p /etc/systemd/system/ollama.service.d
cat <<EOF | sudo tee /etc/systemd/system/ollama.service.d/override.conf
[Service]
Environment="OLLAMA_HOST=0.0.0.0:11434"
EOF

sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl restart ollama

echo "⏳ [INFO] Warte bis Ollama bereit ist..."

for i in {1..60}; do
  if curl -fsS http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
    echo "✅ [INFO] Ollama API ist bereit."
    break
  fi

  if [ "$i" -eq 60 ]; then
    echo "❌ [ERROR] Ollama wurde nicht rechtzeitig bereit."
    sudo systemctl status ollama --no-pager
    journalctl -u ollama --no-pager -n 50
    exit 1
  fi

  sleep 2
done

ollama pull llama3.1:8b-instruct-q4_K_M
ollama pull qwen2.5:7b-instruct-q4_K_M

echo "✅ [INFO] ollama wurde erfolgreich installiert!"