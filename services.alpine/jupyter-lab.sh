#!/bin/bash
#
# neue Jupyter Umgebung, lokal auf VM
apk update
apk add python3 py3-virtualenv py3-pip

# Installiert und aktiviert Juypter Lab

python3 -m venv /home/alpine/.jupyter
source .jupyter/bin/activate
pip install --upgrade pip
pip install jupyterlab

# Jupyter Libraries fuer AI

# OpenAI API als separater Kernel (Chat)
python3 -m venv .ai
source /home/alpine/.ai/bin/activate
pip install openai
pip install ipykernel
pip install nbconvert
python3 -m ipykernel install --user --name=ai --display-name "Python (ai)"

# RAG
python3 -m venv .rag
source /home/alpine/.rag/bin/activate
pip install ipykernel chromadb pypdf requests tqdm
python3 -m ipykernel install --user --name=rag --display-name "Python (rag)"

# MCP
python3 -m venv .mcp
source /home/alpine/.mcp/bin/activate
pip install ipykernel mcp requests
pip install openai
python3 -m ipykernel install --user --name=mcp --display-name "Python (mcp)"

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
rc-service jupyterlab start
rc-service jupyterlab stop
rc-service jupyterlab restart
rc-service jupyterlab status

# lernkube Public Key
curl https://raw.githubusercontent.com/mc-b/lerncloud/main/ssh/lerncloud >/home/alpine/.ssh/id_rsa
chmod 600 /home/alpine/.ssh/id_rsa

# SSH keine Verwendung von .ssh/known_hosts
cat <<EOF >/home/alpine/.ssh/config
StrictHostKeyChecking no
UserKnownHostsFile /dev/null
LogLevel error
EOF
