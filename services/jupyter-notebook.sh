#!/bin/bash
#

sudo apt-get install -y jupyter-notebook

cat <<%EOF% | sudo tee /etc/systemd/system/jupyter.service
[Unit]
Description=Jupyter Notebook

[Service]
Type=simple
PIDFile=/run/jupyter.pid
ExecStart=/usr/bin/jupyter notebook --ip=0.0.0.0 --port=32188 --no-browser --NotebookApp.token='' --NotebookApp.password=''
User=ubuntu
Group=ubuntu
WorkingDirectory=/home/ubuntu
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
%EOF%

sudo systemctl daemon-reload
sudo systemctl enable jupyter.service
sudo systemctl restart jupyter.service

# lernkube Public Key
curl https://raw.githubusercontent.com/mc-b/lerncloud/main/ssh/lerncloud >~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa

