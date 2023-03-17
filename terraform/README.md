Terraform 
---------

[![](https://embed-fastly.wistia.com/deliveries/41c56d0e44141eb3654ae77f4ca5fb41.jpg)](https://learn.hashicorp.com/tutorials/terraform/infrastructure-as-code?in=terraform%2Faws-get-started&amp;wvideo=mo76ckwvz4)

Quelle: hashicorp
- - -

Terraform ist ein Open-Source- Infrastruktur als Code- Software-Tool, das von HashiCorp entwickelt wurde . Benutzer definieren und stellen die Rechenzentrumsinfrastruktur mithilfe einer deklarativen Konfigurationssprache namens HashiCorp Configuration Language (HCL) oder optional JSON bereit.

So stellen Sie die Infrastruktur mit Terraform bereit:

* **Scope**  - Identifizieren Sie die Infrastruktur für Ihr Projekt.
* **Author**  – Schreiben Sie die Konfiguration für Ihre Infrastruktur.
* **Initialize** `terraform init` – Installieren Sie die Plugins, die Terraform zum Verwalten der Infrastruktur benötigt.
* **Plan** `terraform plan` – Zeigen Sie eine Vorschau der Änderungen an, die Terraform an Ihre Konfiguration anpasst.
* **Apply** `terraform apply` – Nehmen Sie die geplanten Änderungen vor.
* **Destroy** `terraform destroy` – Löschen Sie die Infrastruktur, wenn Sie sie nicht mehr benötigen. 

**Tipp**: jede Cloud Plattform erlaubt die eben durchgeführte Aktion, z.B. das erstellen einer VM, als Template zu speichern. In diesem Template finden Sie die Werte welche nachher in die Terraform Konfiguration übertragen werden können, z.B. der Name einer VM-Vorlage.

Für die nachfolgenden Beispiele sind die CLI für Azure, AWS und das Terraform CLI zu installieren.

* [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/)
* [AWS CLI](https://aws.amazon.com/de/cli/)
* [Terraform Installation](https://learn.hashicorp.com/tutorials/terraform/install-cli?in=terraform/aws-get-started)

Um eine VM in einer der Cloud Umgebungen (AWS, Azure, MAAS) zu erstellen, genügt es dieses Repository zu clonen, Terraform zu initialiseren und sich dem dem jeweilige CLI in der Cloud einzuloggen.

    git clone https://github.com/mc-b/lerncloud
    # In der Cloud Anmelden
    cd lerncloud/terraform
    # main.tf Eintrag `source` aktivieren
    terraform init
    terraform apply 
    
Wird die VM nicht mehr benötigt, kann sie wieder gelöscht werden:

    terraform destroy    
    
Für eine Liste der Module siehe [Module](../modules/). Statt einer Cloud-init Datei aus dem Verzeichnis, kann eine eigene Cloud-init Datei angegeben werden. 

    terraform apply -var module=<Modulname> -var userdata=<meine Cloud-init Datei>
    
### Lokaler Computer

Installiert [Multipass](https://multipass.run/), mit dem Default Hypervisor für das entsprechende Betriebssystem.

Um dann  eine VM mit einer Introseite zu erstellen:

    git clone https://github.com/lerncloud
    az login
    cd lerncloud/terraform
    # main.tf Eintrag `source = "git::https://github.com/mc-b/terraform-lerncloud-multipass"` aktivieren, andere deaktivieren  
    terraform init
    terraform apply 

### Azure Cloud

In der Azure Cloud eine VM mit einer Introseite erstellen: 

    git clone https://github.com/tbz-it/lerncloud
    az login
    cd lerncloud/terraform
    # main.tf Eintrag `source = "git::https://github.com/mc-b/terraform-lerncloud-azure"` aktivieren, andere deaktivieren  
    terraform init
    terraform apply 
    
### AWS Cloud

In der AWS Cloud eine VM mit einer Introseite erstellen:

    git clone https://github.com/mc-b/lerncloud
    
    aws configure
        AWS Access Key ID [****************....]:
        AWS Secret Access Key [****************....]:
        Default region name [us-west-2]: us-east-1
        Default output format [None]:    
    
    cd lerncloud/terraform
    # main.tf Eintrag `source = "git::https://github.com/mc-b/terraform-lerncloud-aws"` aktivieren, andere deaktivieren    
    terraform init
    terraform apply 
    
**Tipp** AWS Academy: statt Credentials in `~/.aws/credentials` zu Speichern. Credentials, z.B. in `config.txt` speichern und Umgebungsvariable `AWS_CONFIG_FILE` setzen.    

### MAAS.io

    git clone https://github.com/mc-b/lerncloud
    cd lerncloud/terraform
    
    # main.tf Eintrag `source = "git::https://github.com/mc-b/terraform-lerncloud-maas"` aktivieren  
    # und Variablen nachtragen bzw. setzen
    url      = "http://<IP Rack Controller>:5240/MAAS"
    key      = "API Key vom Rack Controller"
    vpn      = "<VPN bzw. AZ>"
    
    terraform init
    terraform apply 
    
Die Nummer hinter dem Modulnamen, ergibt den Hostanteil für das VPN, siehe [Einbinden der Clients und Portweiterleitung](https://github.com/mc-b/lernmaas/blob/master/doc/MAAS/GatewayClient.md).

Weitere Beispiele siehe Terraform Modul [terraform-lerncloud-maas](https://github.com/mc-b/terraform-lerncloud-maas/blob/main/examples/main.tf).

### MAAS.io mit ganzen Klassen 

Neben dem Erzeugen einzelner VMs können auch VMs für gesamte Klassen erstellt werden. Dazu werden [Terraform Workspaces](https://www.terraform.io/language/state/workspaces) und das Modul [terraform-lerncloud-lernmaas](https://github.com/mc-b/terraform-lerncloud-lernmaas) verwendet.

    git clone https://github.com/mc-b/lerncloud
    cd lerncloud/terraform
    
    # main.tf Eintrag `source = "git::https://github.com/mc-b/terraform-lerncloud-lernmaas"` aktivieren bzw. eintragen  
    # und Variablen nachtragen bzw. setzen
    url      = "http://<IP Rack Controller>:5240/MAAS"
    key      = "API Key vom Rack Controller"
    vpn      = "<VPN bzw. AZ>"  
    # evtl. setzen: Anzahl VM per VM Host (bei 6 KVM * 4 = 24 VMs) und Offset fuer die erste Host-IP
    vm_per_host = 4
    vm_offset = 10 
    
Weil `outputs.tf` nur von einer VM ausgeht, jetzt aber eine List von VMs kommt, ist `outputs.tf` entweder Umzubauen oder zu löschen.

Dann kann pro Klasse ein neuer Terraform Workspace angelegt werden
    
    terraform workspace new ap19a
    terraform workspace select ap19a
     
und wie gewohnt Terraform ausgeführt werden:

    terraform init
    terraform apply 
    
Es werden `Anzahl KVM * 4` VMs angelegt. Als Hostname wird `<modul>-<host-no>-<terraform workspace>`, z.B. `m122-10-ap19a`, `m122-11-ap19a` etc. verwendet.

### Proxmox

Neu gibt es eine rudimentäre Unterstützung von [Proxmox](https://www.proxmox.com/de/). Rudimentär, weil die Cloud-init und Terraform Unterstützung von Proxmox einige Einschränkungen hat, u.a.:

* Die Cloud-init Dateien müssen zwingend im Verzeichnis `/var/lib/vz/snippets` Verzeichnis abgelegt werden. Relative Pfade, z.B. `../modules.base.yaml` sind nicht zulässig.
* Meta Daten, z.B. wie im MAAS um z.B. automatisch WireGuard zu Konfigurieren wird nicht unterstützt.
* Das IP-Netzwerk (192.168.1.1) und GW-Adresse ist fix im [lerncloud-proxmox](https://github.com/mc-b/terraform-lerncloud-proxmox) Modul hinterlegt und muss ggf. angepasst werden. 
* Die effektive IP-Adresse ergibt sich aus der fixen Vorgabe und der Nummern im Hostnamen, z.B. base-10 ergibt IP-Adresse 192.168.1.110.

Ausserdem muss zuerst ein Cloud-init VM Template angelegt werden, wie im [lerncloud-proxmox](https://github.com/mc-b/terraform-lerncloud-proxmox) Modul beschrieben.

Anschliessend in die Proxmox Maschine einloggen, Snippets Verzeichnis anlegen und ein paar Cloud-init Scripte aufbereiten als Snippets.

    mkdir -p /var/lib/vz/snippets
    
    wget -O /var/lib/vz/snippets/base.yaml https://github.com/mc-b/lerncloud/raw/main/modules/base.yaml
    wget -O /var/lib/vz/snippets/microk8smaster.yaml https://github.com/mc-b/lerncloud/raw/main/modules/microk8smaster.yaml
    wget -O /var/lib/vz/snippets/microk8sworker.yaml https://github.com/mc-b/lerncloud/raw/main/modules/microk8sworker.yaml
    
Dann kann in der `main.tf` Datei als `userdata` eines der drei Scripte, z.B. `base.yaml`, angegeben werden.

ProxMox User, für Zugriff via Terraform anlegen, Password ggf. ändern

    pveum role add TerraformProv -privs "Datastore.AllocateSpace Datastore.Audit Pool.Allocate Sys.Audit VM.Allocate VM.Audit VM.Clone VM.Config.CDROM VM.Config.CPU VM.Config.Cloudinit VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Monitor VM.PowerMgmt"
    pveum user add terraform-prov@pve --password insecure
    pveum aclmod / -user terraform-prov@pve -role TerraformProv
    
Und zum Schluss, mittels Umgebungsvariablen `TF_VAR_xxx` festlegen welche Proxmox Umgebung angesprochen werden soll, z.B.:

    TF_VAR_url=https://localhost:8006/api2/json
    TF_VAR_key=insecure
    
**WireGuard**

Um wie bei MAAS WireGuard zu aktivieren, ist im Cloud-image die WireGuard Konfiguration zu hinterlegen. Bei mehreren VPNs ist mit mehreren Cloud-images zu arbeiten.
Die WireGuard Konfiguration muss Base64 encoded sein, siehe [updateaz](https://github.com/mc-b/lernmaas/tree/master/helper#updateaz).

    virt-customize -a /var/lib/vz/cloudimg/jammy-server-cloudimg-amd64.img --mkdir /opt/lernmmas
    virt-customize -a /var/lib/vz/cloudimg/jammy-server-cloudimg-amd64.img --copy-in wireguard:/opt/wireguard/wireguard

Leider wird, wenn im Cloud-init Script nicht explizit angegeben, der Hostname nicht gesetzt. Somit kann das VPN Script auch WireGuard nicht aktivieren.

Abhilfe schafft eine Erweiterungen des [Cloud-init Moduls](https://github.com/mc-b/terraform-lerncloud-proxmox), welche den Hostnamen setzt und anschliessend das VPN Script nochmals ausführt.

      connection {
        type     = "ssh"
        host     = self.default_ipv4_address
        user     = "ubuntu"
        password = "insecure"
      }
      provisioner "remote-exec" {
        inline = [
          "sudo hostnamectl set-hostname  ${var.module}",
          "curl -sfL https://raw.githubusercontent.com/mc-b/lerncloud/main/services/vpn.sh | bash -",    
        ]
      } 

### Terraform in eigene Module Einbinden

Um Terraform in seine eigenen Module einzubinden, ist im Repository eine Datei `main.tf` mit folgendem Inhalt anzulegen:

    module "lerncloud" {
      #source     = "git::https://github.com/mc-b/terraform-lerncloud-multipass"      
      #source     = "git::https://github.com/mc-b/terraform-lerncloud-aws"
      #source     = "git::https://github.com/mc-b/terraform-lerncloud-azure"
      #source     = "git::https://github.com/mc-b/terraform-lerncloud-maas"
      #source     = "git::https://github.com/mc-b/terraform-lerncloud-proxmox"
               
      module     = "m122"
      userdata   = "cloud-init.yaml"
    }
    
Die Variable `module` ist auf den Namen des Moduls zu ändern.    

Als nächstes ist eine `cloud-init.yaml` anzulegen. In dieser Datei erfolgt die eigentliche Installation der Software. Für Beispiele siehe [Migration](../migration/) und [Services](../services).

Als letztes braucht es noch eine `outputs.tf` Datei, wo nach Erstellung der Umgebung, IP-Adresse und FQDN ausgibt. Dabei kann die [outputs.tf](outputs.tf) Vorlage 1:1 verwendet werden.
    
Anschliessend ist das Repository zu klonen.

    git clone https://github.com/tbz-it/m122
    
Je nach dem welche Cloud angesprochen werden soll, ist der `#` aus einem der `source` Einträge zu entfernen. Dann noch die Umgebung Anlegen und fertig.

    terraform init
    terraform apply
    
#### Mehrere VMs anlegen

Sollen gleichzeitig mehrere VMs angelegt werden, ist der `module` Eintrag zu kopieren und der Name `lerncloud`, der Modulname und ggf. der Cloud-init Parameter, zu ändern. 

    module "base" {
      source     = "git::https://github.com/mc-b/terraform-lerncloud-multipass"      
      #source     = "git::https://github.com/mc-b/terraform-lerncloud-maas"
      #source     = "git::https://github.com/mc-b/terraform-lerncloud-aws"
      #source     = "git::https://github.com/mc-b/terraform-lerncloud-azure"
      module     = "base"
      userdata   = "../modules/base.yaml"
    }
    
    module "docker" {
      source     = "git::https://github.com/mc-b/terraform-lerncloud-multipass"      
      #source     = "git::https://github.com/mc-b/terraform-lerncloud-maas"
      #source     = "git::https://github.com/mc-b/terraform-lerncloud-aws"
      #source     = "git::https://github.com/mc-b/terraform-lerncloud-azure"

      module     = "docker"
      userdata   = "../modules/docker.yaml"
    } 

Sollen mehrere VMs vom gleichen Type angelegt werden, kann `count` verwendet werden.

    module "lerncloud" {
      source     = "git::https://github.com/mc-b/terraform-lerncloud-multipass"      
      #source     = "git::https://github.com/mc-b/terraform-lerncloud-maas"
      #source     = "git::https://github.com/mc-b/terraform-lerncloud-aws"
      #source     = "git::https://github.com/mc-b/terraform-lerncloud-azure"

      count       = 24
      module     = "base-${format("%02d", count.index + 1)}"
      userdata   = "../modules/base.yaml"
    } 
    
**Provider Problem in Modulen**

Leider funktioniert das letzte Beispiel nicht in der Cloud, weil `count` nicht auf Provider angewandt werden kann.

Mit ein paar Anpassen kann es jedoch zum laufen gebracht werden.

Gewünschtes Modul, z.B. AWS, ins eigene Repository als Unterverzeichnis clonen

    git clone https://github.com/tbz-it/m122
    cd m122
    git clone https://github.com/mc-b/terraform_lerncloud_aws
    
`provider.tf` Datei vom Verzeichnis `terraform_lerncloud_aws` ins aktuelle (m122) Verzeichnis verschieben und `source` auf Modul (terraform_lerncloud_aws) Verzeichnis umswitchen. Ist eine Datei `required_providers.tf` vorhanden, ist diese ins aktuelle (m122) Verzeichnis zu kopieren.

Das Ergebnis, in `main.tf`, sieht wie folgt aus:

    module "lerncloud" {
      source = "./terraform_lerncloud_aws"
      count    = 24
      module   = "base-${format("%02d", count.index + 1)}"
      userdata = "../modules/base.yaml"
    } 

#### Kubernetes

Ein Kubernetes Cluster besteht, in der Regel, aus mehreren VMs. Diese unterteilen sich in Master und Worker Nodes.

Dazu braucht es eine Kombination unterschiedlicher VMs in unterschiedlicher Anzahl.

    module "master" {
      source     = "git::https://github.com/mc-b/terraform-lerncloud-multipass"      
      #source     = "git::https://github.com/mc-b/terraform-lerncloud-maas"
      #source     = "git::https://github.com/mc-b/terraform-lerncloud-aws"
      #source     = "git::https://github.com/mc-b/terraform-lerncloud-azure"

      module     = "master"
      userdata   = "../modules/microk8smaster.yaml"
      mem        = "4GB"
      cpu        = 2
    }
    
    module "worker" {
      source     = "git::https://github.com/mc-b/terraform-lerncloud-multipass"      
      #source     = "git::https://github.com/mc-b/terraform-lerncloud-maas"
      #source     = "git::https://github.com/mc-b/terraform-lerncloud-aws"
      #source     = "git::https://github.com/mc-b/terraform-lerncloud-azure"

      count       = 2
      module     = "worker-${format("%02d", count.index + 1)}"
      userdata   = "../modules/microk8sworker.yaml"
      mem        = "4GB"
      cpu        = 2
    } 
    
Gleiches Problem, wie oben mit `count`. Die Lösung, sind mehrere Einträge.

    module "master" {
      #source     = "git::https://github.com/mc-b/terraform-lerncloud-multipass"      
      #source     = "git::https://github.com/mc-b/terraform-lerncloud-maas"
      source     = "git::https://github.com/mc-b/terraform-lerncloud-aws"
      #source     = "git::https://github.com/mc-b/terraform-lerncloud-azure"

      module     = "master"
      userdata   = "../modules/microk8smaster.yaml"
      mem        = "4GB"
      cpu        = 2
    }
    
    module "worker-01" {
      #source     = "git::https://github.com/mc-b/terraform-lerncloud-multipass"      
      #source     = "git::https://github.com/mc-b/terraform-lerncloud-maas"
      source     = "git::https://github.com/mc-b/terraform-lerncloud-aws"
      #source     = "git::https://github.com/mc-b/terraform-lerncloud-azure"

      module     = "worker-01"
      userdata   = "../modules/microk8sworker.yaml"
      mem        = "4GB"
      cpu        = 2
    }

    module "worker-02" {
      #source     = "git::https://github.com/mc-b/terraform-lerncloud-multipass"      
      #source     = "git::https://github.com/mc-b/terraform-lerncloud-maas"
      source     = "git::https://github.com/mc-b/terraform-lerncloud-aws"
      #source     = "git::https://github.com/mc-b/terraform-lerncloud-azure"
      module     = "worker-02"
      userdata   = "../modules/microk8sworker.yaml"
      mem        = "4GB"
      cpu        = 2
    }
    
### Links

* [Terraform tips & tricks: loops, if-statements, and gotchas](https://blog.gruntwork.io/terraform-tips-tricks-loops-if-statements-and-gotchas-f739bbae55f9)
* [Why we use Terraform and not Chef, Puppet, Ansible, SaltStack, or CloudFormation](https://blog.gruntwork.io/why-we-use-terraform-and-not-chef-puppet-ansible-saltstack-or-cloudformation-7989dad2865c)    
* [Terraform: Up & Running, 3rd edition](https://blog.gruntwork.io/terraform-up-running-3rd-edition-early-release-is-now-available-4efd0eb2ce0a)