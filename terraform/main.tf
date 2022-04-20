###
# Basis VM

module "lerncloud" {
  source     = "git::https://github.com/mc-b/terraform-lerncloud-maas"
  #source     = "git::https://github.com/mc-b/terraform-lerncloud-multipass"
  #source     = "git::https://github.com/mc-b/terraform-lerncloud-aws"
  #source     = "git::https://github.com/mc-b/terraform-lerncloud-azure"

  # Module Info
  module      = "base-11"
  description = "Basis Modul"
  userdata    = "../modules/base.yaml"

  # VM Sizes  
  #memory   = 2
  #cores    = 1
  #storage  = 32
  #ports    = [ 22, 80 ]

  # Server Access Info
  url      = "http://10.6.37.8:5240/MAAS"
  key      = "${var.key}"
  vpn      = "10-6-37-0"
}

