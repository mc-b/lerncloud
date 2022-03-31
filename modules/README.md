Module und Kurse
----------------

In diesem Kapitel befindet sich voll funktionsfähige Cloud-init Scripts welche zum Erstellen von eigenen VMs verwendet werden können.

Dazu ist zuerst diese Repository zu klonen 

    git clone https://github.com/mc-b/lerncloud.git
    cd lerncloud
    
Und anschliessend kann eine Basisumgebung mit vorbereiteten Verzeichnis, SSH-Keys, WireGuard und Introseite gestartet werden.    
    
    multipass launch --name base --cloud-init modules/base.yaml
    ssh -i ssh/lerncloud ubuntu@base.mshome.net
    
Browser öffnen und [http://base.mshome.net](http://base.mshome.net) anwählen.
    
    
        