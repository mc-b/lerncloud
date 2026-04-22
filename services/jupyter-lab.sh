#!/bin/bash
#
# neue Jupyter Umgebung, lokal auf VM
sudo apt-get install -y --no-install-recommends python3-venv uuid python3-pip

# Installiert und aktiviert Juypter Lab

python3 -m venv ~/.jupyter
source .jupyter/bin/activate
pip install --upgrade pip
pip install jupyterlab

# Jupyter Libraries fuer AI

if [ "$SKIP_LIBRARIES" = "true" ]
then
    echo "Installation Libraries überspringen"
else
    # OpenAI API als separater Kernel (Chat)
    python3 -m venv ~/.ai
    source ~/.ai/bin/activate
    pip install openai pydantic
    pip install ipykernel requests
    pip install nbconvert
    python3 -m ipykernel install --user --name=ai --display-name "Python (ai)"


    # Hugging Face
    python3 -m venv ~/.hf
    source ~/.hf/bin/activate
    pip install -U ipykernel ipywidgets datasets pyarrow huggingface_hub fsspec transformers accelerate sentence-transformers sentencepiece peft pypdf requests tqdm numpy einops
    python3 -m ipykernel install --user --name=rag --display-name "Python (hf)"
    
    # MCP
    python3 -m venv ~/.mcp
    source ~/.mcp/bin/activate
    pip install ipykernel mcp requests
    pip install openai
    python3 -m ipykernel install --user --name=mcp --display-name "Python (mcp)"
    
    # Dapr (Multi Agent)
    python3 -m venv ~/.dapr
    source ~/.dapr/bin/activate
    pip install openai-agents dapr dapr-ext-grpc
    pip install ipykernel
    python3 -m ipykernel install --user --name=dapr --display-name "Python (dapr)"
fi

# Jupyter Lab as Service
cat <<%EOF% | sudo tee /etc/systemd/system/jupyterlab.service
[Unit]
Description=Jupyter Lab

[Service]
Type=simple
PIDFile=/run/jupyter.pid
ExecStart=/home/ubuntu/.jupyter/bin/jupyter lab --ip=0.0.0.0 --port=32188 --no-browser --ServerApp.default_url=/lab --ServerApp.token=''
User=ubuntu
Group=ubuntu
WorkingDirectory=/home/ubuntu
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
%EOF%

sudo systemctl daemon-reload
sudo systemctl enable jupyterlab.service
sudo systemctl restart jupyterlab.service

# lernkube Public Key
curl https://raw.githubusercontent.com/mc-b/lerncloud/main/ssh/lerncloud >~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa

# SSH keine Verwendung von .ssh/known_hosts
cat <<EOF >~/.ssh/config
StrictHostKeyChecking no
UserKnownHostsFile /dev/null
LogLevel error
EOF

# Public IP anhand Cloud Provider setzen, WireGuard ueberschreibt alle
curl -fsSL https://raw.githubusercontent.com/mc-b/lerncloud/main/scripts/get-server-ip.sh | bash | tee ~/data/server-ip

# Eindeutige UUID pro Installation fuer IoT
echo "UUID=\"$(uuid)\"" >~/data/uuid.py

# Umgebungsvariablen fuer K8s AI Server, OpenAI und Hugging Face 
cat <<EOF > ~/data/env.py
KUBECONFIG_AI=""
OPENAI_API_KEY=""
HF_TOKEN=""
EOF

