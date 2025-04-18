#!/bin/bash
#   
#   Installiert Container Tools wie PodMan, Buildah etc.
#   @see https://github.com/containers
#

source /etc/os-release

echo "🚀 [INFO] Starte podman buildah skopeo (Containers) Installation..."

# Ubuntu 20
if [ "${VERSION_CODENAME}" == "focal" ]
then
    sh -c "echo 'deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_18.04/ /' | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list"
    wget -nv https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/xUbuntu_18.04/Release.key -O /tmp/Release.key
    sudo apt-key add - </tmp/Release.key
    sudo apt-get update -qq
    sudo apt-get -qq -y install podman buildah skopeo 
    sudo apt-get -qq -y install fuse-overlayfs

# Containers Tools (ab Ubuntu 22.x)
elif [ "${VERSION_CODENAME}" == "jammy" ]
then
    sudo apt-get update -qq
    sudo apt-get install -y podman buildah skopeo
    pip install podman-compose
# Containers Tools (ab Ubuntu 24.x)
else
    sudo apt-get update -qq
    sudo apt-get install -y podman buildah skopeo podman-compose    
fi

# Enable remote access @see https://www.redhat.com/sysadmin/podman-clients-macos-windows
sudo su - ubuntu -c "systemctl --user enable podman.socket"
sudo loginctl enable-linger ubuntu
sudo systemctl restart podman

echo "✅ [INFO] podman buildah skopeo (Containers) wurde erfolgreich installiert!"
    