#!/bin/bash
#
# neue Jupyter Umgebung, lokal auf VM
apk update
apk add --no-cache python3 py3-virtualenv py3-pip

# Installiert und aktiviert Juypter Lab
su - alpine -c '
  python3 -m venv /home/alpine/.jupyter
  source /home/alpine/.jupyter/bin/activate
  pip install --upgrade pip
  pip install jupyterlab
'

# Jupyter Libraries fuer AI

# OpenAI API als separater Kernel (Chat)
su - alpine -c '
  python3 -m venv /home/alpine/.ai
  source /home/alpine/.ai/bin/activate
  pip install --upgrade pip  
  pip install openai pydantic
  pip install ipykernel requests
  pip install nbconvert
  python3 -m ipykernel install --user --name=ai --display-name "Python (ai)"
'

# RAG - onnxruntime nicht verfuegbar auf alpine
su - alpine -c '
  python3 -m venv /home/alpine/.hf
  source /home/alpine/.hf/bin/activate
  pip install --upgrade pip    
  pip install -U ipykernel ipywidgets datasets pyarrow huggingface_hub fsspec transformers accelerate sentence-transformers sentencepiece peft pypdf requests tqdm numpy einops
  python3 -m ipykernel install --user --name=rag --display-name "Python (hf)" 
'

# MCP
su - alpine -c '
  python3 -m venv /home/alpine/.mcp
  source /home/alpine/.mcp/bin/activate
  pip install ipykernel mcp requests
  pip install openai  
  python3 -m ipykernel install --user --name=mcp --display-name "Python (mcp)"
'  

# Dapr (Multi Agent)
su - alpine -c '
  python3 -m venv /home/alpine/.dapr
  source /home/alpine/.dapr/bin/activate
  pip install openai-agents dapr dapr-ext-grpc
  pip install ipykernel
  python3 -m ipykernel install --user --name=dapr --display-name "Python (dapr)"
'  

# Jupyter Lab as Service
cat <<'EOF' | tee /etc/init.d/jupyterlab
#!/sbin/openrc-run

name="Jupyter Lab"
description="Jupyter Lab Service"

command="/home/alpine/.jupyter/bin/jupyter"
command_args="lab --ip=0.0.0.0 --port=32188 --no-browser --ServerApp.default_url=/lab --ServerApp.token=''"
command_user="alpine:alpine"
directory="/home/alpine"

pidfile="/run/jupyterlab.pid"
command_background="yes"

depend() {
    need net
}
EOF

chmod +x /etc/init.d/jupyterlab
rc-update add jupyterlab default
rc-service jupyterlab restart

# lernkube Public Key
curl https://raw.githubusercontent.com/mc-b/lerncloud/main/ssh/lerncloud >/home/alpine/.ssh/id_rsa
chmod 600 /home/alpine/.ssh/id_rsa
chown alpine:alpine /home/alpine/.ssh/id_rsa

# SSH keine Verwendung von .ssh/known_hosts
cat <<EOF >/home/alpine/.ssh/config
StrictHostKeyChecking no
UserKnownHostsFile /dev/null
LogLevel error
EOF
chmod 600 /home/alpine/.ssh/config
chown alpine:alpine /home/alpine/.ssh/config

# Umgebungsvariablen fuer K8s AI Server, OpenAI und Hugging Face 
su - alpine -c '
cat <<EOF > ~/work/env.py
KUBECONFIG_AI=""
OPENAI_API_KEY=""
HF_TOKEN=""
EOF
'
