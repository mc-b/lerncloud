#!/bin/bash
#
# Installiert longhorn 

# Funktionen
wait_for_pods() {
  namespace=$1
  echo "Warte, bis alle Pods im Namespace '$namespace' bereit sind..."

  while true; do
    not_ready=$(kubectl get pods -n "$namespace" --no-headers 2>/dev/null | grep -v 'Running\|Completed\|Succeeded' | wc -l)
    if [ "$not_ready" -eq 0 ]; then
      echo "✅ Alle Pods im Namespace '$namespace' sind bereit."
      break
    fi
    echo -n "."
    sleep 5
  done
}

wait_for_jobs() {
  namespace=$1
  echo "Warte, bis alle Jobs im Namespace '$namespace' abgeschlossen sind..."

  while true; do
    incomplete=$(kubectl get jobs -n "$namespace" --no-headers 2>/dev/null | awk '$2 != $3 {print $1}' | wc -l)
    if [ "$incomplete" -eq 0 ]; then
      echo "✅ Alle Jobs im Namespace '$namespace' sind abgeschlossen."
      break
    fi
    echo "."
    sleep 5
  done
}

echo "🚀 Starte Longhorn Installation..."

# Kubernetes-Labels für Master/Control-Plane setzen
kubectl label nodes $(kubectl get nodes -o custom-columns=NAME:.metadata.name | awk 'NR==2') node-role.kubernetes.io/master=
kubectl label nodes $(kubectl get nodes -o custom-columns=NAME:.metadata.name | awk 'NR==2') node-role.kubernetes.io/control-plane=

# Helm Repo hinzufügen
helm repo add longhorn https://charts.longhorn.io
helm repo update
  
helm install longhorn longhorn/longhorn \
 --namespace longhorn-system --create-namespace \
 --set defaultSettings.kubernetesClusterAutodetectionMethod="custom" \
 --set defaultSettings.kubeletRootDir="/var/snap/microk8s/common/var/lib/kubelet" \
 --set csi.kubeletRootDir="/var/snap/microk8s/common/var/lib/kubelet"  

# Warten, bis alle Pods laufen
wait_for_pods "longhorn-system"

# Optional: Auf Jobs warten, falls vorhanden (z.B. Migrationsjobs)
wait_for_jobs "longhorn-system"

echo "🏁 Longhorn wurde erfolgreich installiert!"

# Weitere Konfigurationsanpassungen (aus Deinem NB)
echo "🔧 Setze StorageClass auf 'longhorn' als Standard..."
kubectl patch storageclass longhorn -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

echo "🔧 Erstelle Default PersistentVolumeClaims"
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: longhorn-rwo
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: longhorn
  resources:
    requests:
      storage: 2Gi
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: longhorn-rwx 
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: longhorn
  resources:
    requests:
      storage: 2Gi
EOF