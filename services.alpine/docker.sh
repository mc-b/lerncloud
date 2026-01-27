#!/bin/bash
#   
#   Installiert Docker-CE
#

echo "🚀 [INFO] Starte docker.io Installation..."
####
# Installation Docker
doas apk update 
doas apk add docker docker-compose
doas usermod -aG docker alpine 

echo "✅ [INFO] docker.io wurde erfolgreich installiert!"