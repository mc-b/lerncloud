###
#   Outputs wie IP-Adresse und DNS Name
#

output "ip_vm" {
  value       = module.wireguard.*.ip_vm
  description = "The IP address of the server instance."
}

output "fqdn_vm" {
  value       = module.wireguard.*.fqdn_vm
  description = "The FQDN of the server instance."
}

output "description" {
  value       = module.wireguard.*.description
  description = "Description VM"
}


# Einfuehrungsseiten



