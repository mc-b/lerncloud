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

ollama pull llama3.1:8b-instruct-q4_K_M
ollama pull qwen2.5:7b-instruct-q4_K_M

echo "✅ [INFO] ollama wurde erfolgreich installiert!"