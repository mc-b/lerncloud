#!/bin/bash
#   
#   Installiert Docker-CE
#

echo "🚀 [INFO] Starte docker.io Installation..."
####
# Installation Docker
apk update 
apk add docker docker-compose
usermod -aG docker alpine 

echo "✅ [INFO] docker.io wurde erfolgreich installiert!"