#!/bin/bash
#
#   Installiert Backstage.io
#

echo "🚀 [INFO] Starte Backstage 1.38.1 Installation..."

sudo apt-get install -y python3 g++ build-essential docker.io git

echo "- 📥 [INFO] nvm installieren"
# Download and install nvm:
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.2/install.sh | bash

# in lieu of restarting the shell
source "$HOME/.nvm/nvm.sh"

echo "- 📥 [INFO] Node.js Version 20 installieren"
# Download and install Node.js:
nvm install 20

# Yarn
npm install -g corepack

# Backstage (braucht Docker)
echo "- 📥 [INFO] Backstage downloaden"
cd $HOME
rm -rf backstage
docker run --rm registry.gitlab.com/ch-mc-b/autoshop-ms/infra/backstage/backstage-app:1.38.1 /bin/cat /app/backstage.tgz | tar xzf -

echo "✅ [INFO] Backstage wurde erfolgreich installiert!"