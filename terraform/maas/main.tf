terraform {
  required_providers {
    maas = {
      source = "suchpuppet/maas"
      version = "3.1.3"
    }
  }
}

provider "maas" {
    # Configuration options
    api_version = "2.0"
    api_key = "nC83nVyLDWKF8zxvPq:VnYukvR9Yh3w9jRDUe:FdU7sFWJu8DHjAeRumRNmZfasNBDqgXa"
    api_url = "http://10.6.37.8:5240/MAAS"
}

resource "maas_instance" "vm" {
    deploy_hostname = var.module
    user_data       = base64encode(data.template_file.userdata.rendered)
    release_erase   = false
}


