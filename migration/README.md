Migration LernMAAS Scripts
------------------------

Die wichtigste Änderung ist, dass LernMAAS [config.yaml](https://github.com/mc-b/lernmaas/blob/master/config.yaml) Einträge jetzt Scripts sind.

### Beispiel Modul 122

Ein Eintrag in [config.yaml](https://github.com/mc-b/lernmaas/blob/master/config.yaml) lässt sich wie folgt übersetzen:

[config.yaml](https://github.com/mc-b/lernmaas/blob/master/config.yaml)

    m122:
      vm:  
        storage: 8
        memory:  2048
        cores: 1
        count: 2
      services:
        nfs: true
        docker: false
        k8s: 
        wireguard: use
        ssh: generate
        samba: true
        firewall: false
      scripts: 
      repositories: https://github.com/tbz-it/M122 
      
- - - 

[cloud-init.yaml](https://github.com/tbz-it/M122/blob/master/cloud-init.yaml)
     
    #cloud-config
    users:
      - name: ubuntu
        sudo: ALL=(ALL) NOPASSWD:ALL
        groups: users, admin
        shell: /bin/bash
        lock_passwd: false
        plain_text_passwd: 'insecure'       
        ssh_authorized_keys:
          - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDUHol1mBvP5Nwe3Bzbpq4GsHTSw96phXLZ27aPiRdrzhnQ2jMu4kSgv9xFsnpZgBsQa84EhdJQMZz8EOeuhvYuJtmhAVzAvNjjRak+bpxLPdWlox1pLJTuhcIqfTTSfBYJYB68VRAXJ29ocQB7qn7aDj6Cuw3s9IyXoaKhyb4n7I8yI3r0U30NAcMjyvV3LYOXx/JQbX+PjVsJMzp2NlrC7snz8gcSKxUtL/eF0g+WnC75iuhBbKbNPr7QP/ItHaAh9Tv5a3myBLNZQ56SgnSCgmS0EUVeMNsO8XaaKr2H2x5592IIoz7YRyL4wlOmj35bQocwdahdOCFI7nT9fr6f insecure@lerncloud
    # login ssh and console with password
    ssh_pwauth: true
    disable_root: false   
    runcmd:
      - curl -sfL https://raw.githubusercontent.com/mc-b/lerncloud/main/services/storage.sh | bash -
      - curl -sfL https://raw.githubusercontent.com/mc-b/lerncloud/main/services/vpn.sh | bash -
      - curl -sfL https://raw.githubusercontent.com/mc-b/lerncloud/main/services/share.sh | bash -
      - sudo su - ubuntu -c "curl -sfL https://raw.githubusercontent.com/mc-b/lerncloud/main/services/repository.sh | bash -s https://github.com/tbz-it/M122"
      - curl -sfL https://raw.githubusercontent.com/mc-b/lerncloud/main/services/intro.sh | bash -

- - -

* `vm` - Einträge beziehen sich auf MAAS.io und können ignoriert werden.

`services`
* `nfs` - `curl -sfL https://raw.githubusercontent.com/mc-b/lerncloud/main/services/storage.sh | bash -`
* `wireguard` - `curl -sfL https://raw.githubusercontent.com/mc-b/lerncloud/main/services/vpn.sh | bash -`
* `ssh` - entfällt, bzw. wird direkt im Cloud-init Script abgehandelt.
* `samba` - `curl -sfL https://raw.githubusercontent.com/mc-b/lerncloud/main/services/share.sh | bash -`
* `firewall` - wurde auch in LernMAAS nie ausgewertet, entfällt.
* `scripts` - die Script Einträge wandern, hinten an das Script `sudo su - ubuntu -c "curl -sfL https://raw.githubusercontent.com/mc-b/lerncloud/main/services/repository.sh | bash -s https://github.com/tbz-it/M122"`
* `curl -sfL https://raw.githubusercontent.com/mc-b/lerncloud/main/services/intro.sh | bash -` - Erstellt eine Introseite aus README.md etc. Und kann aus den `scripts/install.sh` entfernt werden.

Für **Terraform** wir ein [main.tf](https://github.com/tbz-it/M122/blob/master/main.tf) benötigt.

### Beispiel Modul 437

[config.yaml](https://github.com/mc-b/lernmaas/blob/master/config.yaml)

    m437:
      vm:  
        ...
      services:
        ...
        k8s: k3s
        ...
      scripts: 
      repositories: https://github.com/tbz-it/M437 
      
- - -

[cloud-init.yaml](https://github.com/tbz-it/M122/blob/master/cloud-init.yaml)   

    #cloud-config
    ... 
    runcmd:
      - curl -sfL https://raw.githubusercontent.com/mc-b/lerncloud/main/services/storage.sh | bash -
      - curl -sfL https://raw.githubusercontent.com/mc-b/lerncloud/main/services/vpn.sh | bash -
      - curl -sfL https://raw.githubusercontent.com/mc-b/lerncloud/main/services/share.sh | bash -
      - curl -sfL https://raw.githubusercontent.com/mc-b/lerncloud/main/services/k3s.sh | bash -
      - sudo su - ubuntu -c "curl -sfL https://raw.githubusercontent.com/mc-b/lerncloud/main/services/repository.sh | bash -s https://github.com/tbz-it/M437"
      - curl -sfL https://raw.githubusercontent.com/mc-b/lerncloud/main/services/intro.sh | bash -

- - -

* `k8s: k3s` - `curl -sfL https://raw.githubusercontent.com/mc-b/lerncloud/main/services/k3s.sh | bash -`

Für **Terraform** wir ein [main.tf](https://github.com/tbz-it/M437/blob/master/main.tf) benötigt.

Migration K3s nach MicroK8s
---------------------------

Um eine homogene Umgebung zur Verfügung zu stellen, sollte statt [K3s](https://k3s.io/) - [MicroK8s](https://microk8s.io/) verwendet werden.

Dazu muss zuerst der Script im `cloud-init` Script ausgetauscht werden:

    - curl -sfL https://raw.githubusercontent.com/mc-b/lerncloud/main/services/k3s.sh | bash -
    
ersetzen mit

    - curl -sfL https://raw.githubusercontent.com/mc-b/lerncloud/main/services/microk8s.sh | bash -    

Anschliessend müssen ggf. die Port Einträge in den Kubernetes YAML Dateien angepasst werden. Das, weil K3s Services, sofern der Port frei ist, direkt auf dem `Port` Eintrag im Service zur Verfügung stellt.

Z.B. hier "OS Ticket" auf Port 80.

    apiVersion: v1
    kind: Service
    metadata:
      name: osticket
      labels:
        app: osticket
        group: iot
        tier: frontend
    spec:
      type: LoadBalancer
      ports:
      - port: 80
        protocol: TCP
        
Es gibt zwei Varianten den Port anzupassen:

a) Im der Kubernetes Service YAML Datei `nodePort` zwischen 30000 - 32768 (Standard Ports Kubernetes) eintragen

      ports:
      - port: 80
        nodePort: 30080          
        protocol: TCP

b) Den Service entfernen und mittels `hostPort` im Deployment/Pods einen beliebigen Port eintragen

    spec:
      containers:
      - name: osticket
        image: campbellsoftwaresolutions/osticket
        ports:
        - containerPort: 80
          hostPort: 80
          name: osticket        
      
Variante b) sollte nicht bei Kubernetes Clustern verwendet werden, weil der Port nur auf der Node verfügbar ist, wo der Pod gestartet wurde.      

Migration LernKube Scripts
------------------------

Alle [LernKube](https://github.com/mc-b/lernkube) Umgebungen basieren auf der gleichen Kubernetes Umgebung.

Erweiterungen und Detailanpassungen erfolgen in den Installationsscripts der entsprechenden Repositories, z.B. [duk/script/install.sh](https://github.com/mc-b/duk/blob/master/scripts/install.sh).

Mittels dem Cloud-init Script [k8smaster.yaml](../modules/k8smaster.yaml) wird die Kubernetes Umgebung erstellt.

Durch Anfügen, weitere Repositories, die Erweiterungen und Detailanpassungen durchgeführt:

      - sudo su - ubuntu -c "curl -sfL https://raw.githubusercontent.com/mc-b/lerncloud/main/services/repository.sh | bash -s https://github.com/mc-b/misegr"
      - sudo su - ubuntu -c "curl -sfL https://raw.githubusercontent.com/mc-b/lerncloud/main/services/repository.sh | bash -s https://github.com/mc-b/duk"
  
