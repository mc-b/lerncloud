#!/bin/bash
#   
#   Installiert Rancher k3s Control Node! ohne Ingress Controller traefik - dafuer nginx (zu Schulungszwecken)
#   als root starten
#
set +e  # Fehler ignorieren
echo "🚀 [INFO] Starte k3s Installation..."

# Basis-Parameter (DEINE)
BASE_ARGS="server --cluster-init --disable traefik --disable servicelb"

WG_IFACE=""
WG_IP=""

# Alle WireGuard-Interfaces durchgehen und das erste mit IPv4 nehmen
for iface in $(wg show interfaces 2>/dev/null); do
  ip4="$(ip -4 -o addr show dev "$iface" 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1)"

  if [ -n "$ip4" ]; then
    WG_IFACE="$iface"
    WG_IP="$ip4"
    break
  fi
done

if [ -n "$WG_IFACE" ] && [ -n "$WG_IP" ]; then
  echo "🔐 [INFO] WireGuard erkannt ($WG_IFACE: $WG_IP)"
  K3S_ARGS="$BASE_ARGS \
    --node-ip=$WG_IP \
    --advertise-address=$WG_IP \
    --flannel-iface=$WG_IFACE"
else
  echo "🌍 [INFO] Kein WireGuard mit IPv4 gefunden – benutze Default-Netz"
  K3S_ARGS="$BASE_ARGS"
fi

echo "▶️ [INFO] k3s Args: $K3S_ARGS"

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="$K3S_ARGS" sh -

mkdir -p /home/ubuntu/.kube
sudo chmod +r /etc/rancher/k3s/k3s.yaml
ln -s /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config

echo "- 🔧 [INFO] kubectl und helm einrichten"
sudo ln -sf /usr/local/bin/k3s /usr/local/bin/kubectl
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

###
# Add-ons  
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# Persistente Datenablage (fix)
echo "- 🔧 [INFO] Persistente Dateiablage /data einrichten"
kubectl apply -f https://raw.githubusercontent.com/mc-b/lerncloud/master/data/DataVolume.yaml

echo "✅ [INFO] k3s wurde erfolgreich installiert!"