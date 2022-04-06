Services
--------

Scripts welche System Dienste wie z.B. Docker, Kubernetes, NFS etc. installieren.

Bestimmte Scripts haben Abhängigkeiten. Z.B. muss vor `share.sh` das Script `storage.sh` ausgeführt werden.

### nfs.sh 

Dient zum Einrichten vom Persistenten Speicher, welcher nicht in der VM gespeichert wird. I.d. Regel das Verzeichnis `/home/ubuntu/data`.

**Einbindung in Scripts**

    runcmd:
     - curl -sfL https://raw.githubusercontent.com/mc-b/lerncloud/main/services/storage.sh | bash -
     
**Voraussetzungen**
* Vorhandener NFS Share, z.B. auf dem Rack Server. Siehe [Gemeinsame Datenablage](https://github.com/mc-b/lernmaas/blob/master/doc/MAAS/Install.md#gemeinsame-datenablage-optional).

### vpn.ch

Installiert und Konfiguriert den VPN Zugriff. Siehe [Einbinden der VPN Clients](https://github.com/mc-b/lernmaas/blob/master/doc/MAAS/GatewayClient.md#einbinden-der-vpn-clients).

**Einbindung in Scripts**

    runcmd:
     - curl -sfL https://raw.githubusercontent.com/mc-b/lerncloud/main/services/storage.sh | bash -
     - curl -sfL https://raw.githubusercontent.com/mc-b/lerncloud/main/services/vpn.sh | bash -
     
**Voraussetzungen**
* `storage.sh` Script wurde vorgängig ausgeführt.    
* WireGuard Konfigurationen und Gateway. Siehe [VPN](https://github.com/mc-b/lernmaas/blob/master/doc/MAAS/Gateway.md#vpn).

### share.sh

Stellt einen SMB Share, i.d. Regel das Verzeichnis `/home/ubuntu/data` als Share `\\<ip vm>\data` zu Verfügung.

Ermöglicht es Windows User Dateien auf der Linux VM abzulegen oder zu verändern.

**Einbindung in Scripts**

    runcmd:
     - curl -sfL https://raw.githubusercontent.com/mc-b/lerncloud/main/services/storage.sh | bash -
     - curl -sfL https://raw.githubusercontent.com/mc-b/lerncloud/main/services/vpn.sh | bash -
     - curl -sfL https://raw.githubusercontent.com/mc-b/lerncloud/main/services/share.sh | bash -
     
**Voraussetzungen**
* `storage.sh` Script wurde vorgängig ausgeführt.    

### intro.sh

Erzeugt eine "Willkommenswebseite" mit weiteren Anweisungen für die Benutzer der VM.

Ausserdem wird das Verzeichnis `/home/ubuntu/data` als `http://<ip-vm>/data` zur Verfügung gestellt.

Diese Willkommensseite kann mittels folgenden Dateien angepasst werden:
* `/home/ubuntu/README.md` - Introseite
* `/home/ubuntu/ACCESSING.md` - Informationen wie auf die VM zugegriffen werden kann. z.B. mittels SSH.
* `/home/ubuntu/SERVICES.md` - Evtl. Services inkl. URLs welche in der VM zu Verfügung stehen.

Diese Dateien können z.B. mittels dem `Cloud-init` Script erzeugt werden. Siehe z.B. [base.yaml](../modules/base.yaml).

**Einbindung in Scripts**

    write_files:
     - content: |
        # Willkommen
       path: /home/ubuntu/README.md
       permissions: '0644' 
    runcmd:
      - curl -sfL https://raw.githubusercontent.com/mc-b/lerncloud/main/services/storage.sh | bash -
      - curl -sfL https://raw.githubusercontent.com/mc-b/lerncloud/main/services/vpn.sh | bash -
      - curl -sfL https://raw.githubusercontent.com/mc-b/lerncloud/main/services/share.sh | bash -
      - curl -sfL https://raw.githubusercontent.com/mc-b/lerncloud/main/services/intro.sh | bash -

**Voraussetzungen**
* `storage.sh` Script wurde vorgängig ausgeführt.

### repository.sh

Bindet Repositories, welche für [LernMAAS](https://github.com/mc-b/lernmaas) erstellt wurden, ein.

**Einbindung in Scripts**

    runcmd:
      - curl -sfL https://raw.githubusercontent.com/mc-b/lerncloud/main/services/storage.sh | bash -
      - curl -sfL https://raw.githubusercontent.com/mc-b/lerncloud/main/services/vpn.sh | bash -
      - curl -sfL https://raw.githubusercontent.com/mc-b/lerncloud/main/services/share.sh | bash -
      - sudo su - ubuntu -c "curl -sfL https://raw.githubusercontent.com/mc-b/lerncloud/main/services/repository.sh | bash -s https://github.com/tbz-it/M122"
      - curl -sfL https://raw.githubusercontent.com/mc-b/lerncloud/main/services/intro.sh | bash -

**Voraussetzungen**
* Vorgängig müssen die Services/Script laut [config.yaml](https://github.com/mc-b/lernmaas/blob/master/config.yaml) bzw. deren LernCloud Entsprechungen ausgeführt werden.

 
