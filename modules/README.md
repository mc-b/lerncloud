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

### [microk8smaster.yaml](microk8smaster.yaml) und [microk8sworker.yaml](microk8sworker.yaml)

Kubernetes Umgebung, basierend auf [MicroK8s](https://microk8s.io/). Mit zwei Cloud-init Scripts, für Master und Worker Nodes.

Basiert auf [base.yaml](base.yaml) mit folgenden Erweiterungen für den Master
* [MicroK8s](https://microk8s.io/) kleine Kubernetes Umgebung mit integriertem DNS Server
* Ingress Dienst (Reverse Proxy)
* Kubernetes Dashboard
* Persistente Ablage, bzw. `PersistenVolume` in Kubernetes.

Die Worker Nodes beinhalten nur [MicroK8s](https://microk8s.io/).

Für die Verwendung mit Terraform siehe [hier](../terraform#kubernetes)

### [Modul 122](https://github.com/tbz-it/M122/blob/master/cloud-init.yaml)

[Abläufe mit einer Scriptsprache automatisieren](https://www.modulbaukasten.ch/module/122/3/de-DE?title=Abl%C3%A4ufe-mit-einer-Scriptsprache-automatisieren) mit:
* Apache PHP Umgebung
* PowerShell
* Introseite

### [Modul 437](https://github.com/tbz-it/M437/blob/master/cloud-init.yaml) 

[Im Support arbeiten](https://www.modulbaukasten.ch/module/437/1/de-DE?title=Im-Support-arbeiten) mit:
* OS Ticket Applikation
* MySQL Datenbank

### [k8smaster.yaml](k8smaster.yaml)

Kubernetes Umgebung wie sie von [LernKube](https://github.com/mc-b/lernkube) verwendet wird.





