Module und Kurse
----------------

In diesem Kapitel befindet sich voll funktionsfähige Cloud-init Scripts welche zum Erstellen von eigenen VMs verwendet werden können.

Dazu ist zuerst diese Repository zu klonen 

    git clone https://github.com/mc-b/lerncloud.git
    cd lerncloud
    
Und anschliessend kann eine [Basisumgebung](base.yaml) mit vorbereiteten Verzeichnis, SSH-Keys, WireGuard und Introseite gestartet werden.    
    
    multipass launch --name base --cloud-init modules/base.yaml
    multipass set client.primary-name=base
    multipass shell base

Alternativ kann mittels `ssh` auf die VM zugegriffen werden.    

    ssh -i ssh/lerncloud ubuntu@base
    
Browser öffnen und [http://base](http://base) anwählen.

Dateiexplorer öffnen und mittels `\\base` Share öffnen.

 
### Beispiele

       