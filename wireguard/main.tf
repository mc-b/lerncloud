###
# Basis VM

module "wireguard" {
  #source      = "./terraform-lerncloud-module"
  #source     = "git::https://github.com/mc-b/terraform-lerncloud-maas"
  source = "git::https://github.com/mc-b/terraform-lerncloud-aws"
  #source     = "git::https://github.com/mc-b/terraform-lerncloud-azure"


  # Module Info
  module      = "wireguard-${terraform.workspace}"
  description = "WireGuard Server"
  userdata    = "cloud-init.yaml"

  # VM Sizes  
  memory  = 2
  cores   = 1
  storage = 16
  ports   = [22, 8000, 3000, 51820]

  # Server Access Info
  url = var.url
  key = var.key
  vpn = var.vpn
}

