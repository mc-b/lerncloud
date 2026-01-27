#!/bin/bash
#
# neue Jupyter Umgebung, lokal auf VM
doas apk update
doas apk add python3 py3-virtualenv py3-pip

# Installiert und aktiviert Juypter Lab

python3 -m venv ~/.jupyter
source .jupyter/bin/activate
pip install --upgrade pip
pip install jupyterlab

# Jupyter Libraries fuer AI

# OpenAI API als separater Kernel (Chat)
python3 -m venv .ai
source ~/.ai/bin/activate
pip install openai
pip install ipykernel
pip install nbconvert
python3 -m ipykernel install --user --name=ai --display-name "Python (ai)"

# RAG
python3 -m venv .rag
source ~/.rag/bin/activate
pip install ipykernel chromadb pypdf requests tqdm
python3 -m ipykernel install --user --name=rag --display-name "Python (rag)"

# MCP
python3 -m venv .mcp
source ~/.mcp/bin/activate
pip install ipykernel mcp requests
pip install openai
python3 -m ipykernel install --user --name=mcp --display-name "Python (mcp)"

# Jupyter Lab as Service
cat <<'EOF' | doas tee /etc/init.d/jupyterlab
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

doas chmod +x /etc/init.d/jupyterlab
doas rc-update add jupyterlab default
doas rc-service jupyterlab start
doas rc-service jupyterlab stop
doas rc-service jupyterlab restart
doas rc-service jupyterlab status

# lernkube Public Key
curl https://raw.githubusercontent.com/mc-b/lerncloud/main/ssh/lerncloud >~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa

# SSH keine Verwendung von .ssh/known_hosts
cat <<EOF >~/.ssh/config
StrictHostKeyChecking no
UserKnownHostsFile /dev/null
LogLevel error
EOF
