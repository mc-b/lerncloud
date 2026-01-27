#!/bin/sh
set +e

### 1. Basis-Pakete
apk update
apk add --no-cache \
  curl \
  iptables ip6tables \
  ca-certificates \
  openrc

### 2. Kernel-Module für Kubernetes
cat <<EOF >/etc/modules-load.d/k3s.conf
br_netfilter
overlay
EOF

modprobe br_netfilter
modprobe overlay

### 3. sysctl-Parameter
cat <<EOF >/etc/sysctl.d/99-kubernetes.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system

### 4. Swap deaktivieren (falls vorhanden)
swapoff -a || true
sed -i '/ swap / s/^/#/' /etc/fstab || true

### 5. cgroups Hinweis (nur Warnung, kein Auto-Fix)
if ! mount | grep -q cgroup; then
  echo "WARNUNG: cgroups scheinen nicht aktiv zu sein. Kernel-Boot-Parameter prüfen!"
fi

### 6. k3s Installation (ohne Traefik, kubeconfig lesbar)
curl -sfL https://get.k3s.io | \
  INSTALL_K3S_EXEC="--disable traefik" \
  K3S_KUBECONFIG_MODE="644" \
  sh -

### 7. OpenRC Service aktivieren
rc-update add k3s default
rc-service k3s start

### 8. alpine User als kubectl-Admin
if id alpine >/dev/null 2>&1; then
  mkdir -p /home/alpine/.kube
  chmod +r /etc/rancher/k3s/k3s.yaml
  ln -s /etc/rancher/k3s/k3s.yaml /home/alpine/.kube/config  
  chown -R alpine:alpine /home/alpine/.kube
  chmod 700 /home/alpine/.kube
  grep -q KUBECONFIG /home/alpine/.bashrc || \
    echo 'export KUBECONFIG=$HOME/.kube/config' >> /home/alpine/.bashrc
fi

### 9. Abschlussinfo
echo "k3s Installation abgeschlossen."
