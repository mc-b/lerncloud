#!/bin/bash
#
#   Installiert Backstage.io
#

sudo apt-get install -y python3 g++ build-essential docker.io git

# Download and install nvm:
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.2/install.sh | bash

# in lieu of restarting the shell
\. "$HOME/.nvm/nvm.sh"

# Download and install Node.js:
nvm install 20

# Yarn
npm install -g corepack

