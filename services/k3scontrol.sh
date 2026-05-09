#!/bin/bash
#   
#   Installiert Rancher k3s Control Node! ohne Ingress Controller traefik - dafuer nginx (zu Schulungszwecken)
#   als root starten
#
set +e  # Fehler ignorieren
echo "🚀 [INFO] Starte k3s Installation..."

BASE_ARGS="server --cluster-init --disable servicelb"

WG_IFACE=""
WG_IP=""

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

  TRAEFIK_EXTERNAL_IP="$WG_IP"
else
  echo "🌍 [INFO] Kein WireGuard mit IPv4 gefunden – benutze Default-Netz"
  K3S_ARGS="$BASE_ARGS"

  TRAEFIK_EXTERNAL_IP="$(ip -4 route get 1.1.1.1 | awk '{print $7; exit}')"
fi

echo "▶️ [INFO] k3s Args: $K3S_ARGS"
echo "🌐 [INFO] Traefik externalIP: $TRAEFIK_EXTERNAL_IP"

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="$K3S_ARGS" sh -

echo "⏳ [INFO] Warte auf Kubernetes API..."
until sudo k3s kubectl get nodes >/dev/null 2>&1; do
  sleep 2
done

echo "⚙️ [INFO] Setze Traefik externalIP..."

sudo k3s kubectl apply -f - <<EOF
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: traefik
  namespace: kube-system
spec:
  valuesContent: |-
    additionalArguments:
      - "--api.dashboard=true"
      - "--api.insecure=true"
      - "--providers.kubernetesgateway=true"

    service:
      spec:
        externalIPs:
          - ${TRAEFIK_EXTERNAL_IP}

    ports:
      traefik:
        expose:
          default: true
        exposedPort: 9000
        port: 9000
        protocol: TCP
EOF

echo "⏳ [INFO] Warte auf Traefik Rollout..."
sudo k3s kubectl -n kube-system rollout status deployment/traefik --timeout=180s || true

echo "🔎 [INFO] Traefik Service:"
sudo k3s kubectl get svc traefik -n kube-system -o wide

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