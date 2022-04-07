Module und Kurse
----------------

In diesem Kapitel befindet sich voll funktionsfähige Cloud-init Scripts welche zum Erstellen von eigenen VMs verwendet werden können.

Zum Starten, siehe Kapitel **Quick Start**
* [Lokaler Computer](../intro/)
* [Cloud inkl. LernMAAS](../intro/Cloud.md)
* [Terraform](../terraform/)
 
### [base.yaml](base.yaml)

Einfache Umgebung mit 
* Persistenter Ablage auf dem Rack Server (sofern vorhanden)
* VPN
* SMB Freigabe von `/home/ubuntu/data` als `<Server IP>\data`
* Einer Introseite

### [docker.yaml](docker.yaml)

Docker Umgebung, ohne Kubernetes, zum Erstellen von Container Images.

### [microk8s.yaml](microk8s.yaml)

Kubernetes Umgebung, basierend auf [MicroK8s](https://microk8s.io/).

Basiert auf [base.yaml](base.yaml) mit folgenden Erweiterungen
* [MicroK8s](https://microk8s.io/) kleine Kubernetes Umgebung mit integriertem DNS Server
* Ingress Dienst (Reverse Proxy)
* Kubernetes Dashboard
* Persistente Ablage, bzw. `PersistenVolume` in Kubernetes.

### [k8smaster.yaml](k8smaster.yaml)

Kubernetes Umgebung wie sie von [LernKube](https://github.com/mc-b/lernkube) verwendet wird.





