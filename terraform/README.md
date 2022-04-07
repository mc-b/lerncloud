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

### Azure Cloud

In der Azure Cloud eine VM für das Modul M122 erstellen: 

    git clone https://github.com/mc-b/lerncloud
    az login
    cd lerncloud/terraform
    # main.tf Eintrag `source = "git::https://github.com/mc-b/terraform_lerncloud_azure.git"` aktivieren    
    terraform init
    terraform apply -var module=m122 -var userdata=../../modules/m122.yaml
    
### AWS Cloud

In der AWS Cloud eine VM für das Modul M122 erstellen:

    git clone https://github.com/mc-b/lerncloud
    
    aws configure
        AWS Access Key ID [****************....]:
        AWS Secret Access Key [****************....]:
        Default region name [us-west-2]: us-east-1
        Default output format [None]:    
    
    cd lerncloud/terraform/aws
    # main.tf Eintrag `source = "git::https://github.com/mc-b/terraform_lerncloud_aws.git"` aktivieren    
    terraform init
    terraform apply 
    
**Tipp** AWS Academy: statt Credentials in `~/.aws/credentials` zu Speichern. Credentials, z.B. in `config.txt` speichern und Umgebungsvariable `AWS_CONFIG_FILE` setzen.    

### MAAS.io

    git clone https://github.com/mc-b/lerncloud

Anpassen der Zugriffsinformationen auf die MAAS Umgebung in `maas/main.tf`, Variablen `api_key` und `api_url`.

    cd lerncloud/terraform/maas
    # main.tf Eintrag `source = "git::https://github.com/mc-b/terraform_lerncloud_maas.git"` aktivieren    
    terraform init
    terraform apply 
    
Die Nummer hinter dem Modulnamen, ergibt den Hostanteil für das VPN, siehe [Einbinden der Clients und Portweiterleitung](https://github.com/mc-b/lernmaas/blob/master/doc/MAAS/GatewayClient.md).

**Hinweis**: der Terraform Provider von MAAS unterstützt leider, einige Parameter wie RAM Grösse, AZ nicht und sollte nur verwendet werden, wenn man sich mit MAAS.io auskennt.

### Terraform in eigene Module Einbinden

Um Terraform in seine eigenen Module einzubinden, ist im Repository eine Datei `main.tf` mit folgendem Inhalt anzulegen:

    module "lerncloud" {
      #source     = "git::https://github.com/mc-b/terraform_lerncloud_multipass.git"      
      #source     = "git::https://github.com/mc-b/terraform_lerncloud_aws.git"
      #source     = "git::https://github.com/mc-b/terraform_lerncloud_azure.git"
      #source     = "git::https://github.com/mc-b/terraform_lerncloud_maas.git"
      module     = "m122"
      userdata   = "cloud-init.yaml"
    }
    
Die Variable `module` und `userdata` sind auf den Namen des Moduls und dessen Cloud-init Datei zu ändern.    
    
Anschliessend ist das Repository zu klonen.

    git clone https://github.com/tbz-it/m122
    
Je nach dem welche Cloud angesprochen werden soll, ist der `#` aus einem der `source` Einträge zu entfernen. Dann noch die VM Anlegen und fertig.

    terraform init
    terraform apply
    
**Mehrere VMs anlegen**

Sollen gleichzeitig mehrere VMs angelegt werden, ist der `module` Eintrag zu kopieren und der Name `lerncloud`, der Modulname und ggf. der Cloud-init Parameter, zu ändern.   


    module "master" {
      source     = "git::https://github.com/mc-b/terraform_lerncloud_multipass.git"
      #source     = "git::https://github.com/mc-b/terraform_lerncloud_aws.git"
      #source     = "git::https://github.com/mc-b/terraform_lerncloud_azure.git"
      #source     = "git::https://github.com/mc-b/terraform_lerncloud_maas.git"
      module     = "master"
      userdata   = "../modules/k8smaster.yaml"
    }
    
    module "worker-01" {
      source     = "git::https://github.com/mc-b/terraform_lerncloud_multipass.git"
      #source     = "git::https://github.com/mc-b/terraform_lerncloud_aws.git"
      #source     = "git::https://github.com/mc-b/terraform_lerncloud_azure.git"
      #source     = "git::https://github.com/mc-b/terraform_lerncloud_maas.git"
      module     = "worker-01"
      userdata   = "../modules/k8sworker.yaml"
    } 