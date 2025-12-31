#!/bin/bash
#   
#   Installiert Rancher k3s Control Node! ohne Ingress Controller traefik - dafuer nginx (zu Schulungszwecken)
#   als root starten
#
set +e  # Fehler ignorieren

echo "🚀 [INFO] Starte k3s Installation..."
#!/bin/sh
set -e

echo "🚀 [INFO] Starte k3s Installation..."

# Basis-Parameter (DEINE)
BASE_ARGS="server --cluster-init --disable traefik --disable servicelb"

# Prüfen ob wg0 existiert und eine IPv4 hat
if ip link show wg0 >/dev/null 2>&1; then
  WG_IP="$(ip -4 addr show wg0 | awk '/inet /{print $2}' | cut -d/ -f1)"

  if [ -n "$WG_IP" ]; then
    echo "🔐 [INFO] WireGuard erkannt (wg0: $WG_IP)"
    K3S_ARGS="$BASE_ARGS \
      --node-ip=$WG_IP \
      --advertise-address=$WG_IP \
      --flannel-iface=wg0"
  else
    echo "⚠️ [WARN] wg0 vorhanden aber ohne IPv4 – falle zurück auf NAT"
    K3S_ARGS="$BASE_ARGS"
  fi
else
  echo "🌍 [INFO] Kein WireGuard – benutze Default-Netz (10.0.2.2)"
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