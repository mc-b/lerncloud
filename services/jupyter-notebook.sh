#!/bin/bash
#

pip install jupyter
mkdir -p /home/ubuntu/data

cat <<%EOF% | sudo tee /etc/systemd/system/jupyter.service
[Unit]
Description=Jupyter Notebook

[Service]
Type=simple
PIDFile=/run/jupyter.pid
ExecStart=/home/ubuntu/.local/bin/jupyter notebook --ip=0.0.0.0 --port=8888 --no-browser --NotebookApp.token='' --NotebookApp.password=''
User=ubuntu
Group=ubuntu
WorkingDirectory=/home/ubuntu/data
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
%EOF%

sudo systemctl daemon-reload
sudo systemctl enable jupyter.service
sudo systemctl restart jupyter.service

