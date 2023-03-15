###
# Basis VM

module "lerncloud" {
  #source      = "./terraform-lerncloud-module"
  #source     = "git::https://github.com/mc-b/terraform-lerncloud-maas"
  #source     = "git::https://github.com/mc-b/terraform-lerncloud-lernmaas"    
  source     = "git::https://github.com/mc-b/terraform-lerncloud-multipass"
  #source     = "git::https://github.com/mc-b/terraform-lerncloud-aws"
  #source     = "git::https://github.com/mc-b/terraform-lerncloud-azure"
  #source     = "git::https://github.com/mc-b/terraform-lerncloud-proxmox"   

  # Module Info
  module      = "base-${format("%02d", var.host_no)}-${terraform.workspace}"
  description = "Basis Modul"
  userdata    = "../modules/base.yaml"

  # VM Sizes  
  #memory   = 2
  #cores    = 1
  #storage  = 32
  #ports    = [ 22, 80 ]

  # Server Access Info
  url      = "${var.url}"
  key      = "${var.key}"
  vpn      = "${var.vpn}"
}

