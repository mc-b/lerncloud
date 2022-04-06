Quick Start - lokaler Computer
------------------------------

Installiert [Multipass](https://multipass.run/), mit dem Default Hypervisorm für das entsprechende Betriebssystem.

Erstellt eine Standard Ubuntu VM mit einer Introseite.

Probiert weitere [Module](../modules/) aus.

**Linux & Mac**

    curl -sfL https://raw.githubusercontent.com/mc-b/lerncloud/main/modules/base.yaml | multipass launch --name base --cloud-init

**Windows PowerShell**    

    $wr = Invoke-WebRequest 'https://raw.githubusercontent.com/mc-b/lerncloud/main/modules/base.yaml'
    $wr.content | multipass launch --name base --cloud-init -

**Git clone** 

    git clone https://github.com/mc-b/lerncloud.git
    cd lerncloud
    multipass launch --name base --cloud-init modules/base.yaml

Öffnet einen Browser und wählt die Introseite mittels `http://<name oder ip vm>` an.

In Windows öffnet den Explorer und öffnet den Share mittels `\\<name oder ip vm>\data` an.

Wechselt in die VM mittels 

    multipass set client.primary-name=base
    multipass shell base
    
oder via `SSH` (nur Git clone Variante)
    
    ssh -i ssh/lerncloud ubuntu@base    
