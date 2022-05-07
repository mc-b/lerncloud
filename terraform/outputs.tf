###
#   Outputs wie IP-Adresse und DNS Name
#

output "ip_vm" {
  value = module.lerncloud.*.ip_vm
  description = "The IP address of the server instance."
}

output "fqdn_vm" {
  value = module.lerncloud.*.fqdn_vm
  description = "The FQDN of the server instance."
}
  
output "description" {
  value       = module.lerncloud.*.description
  description = "Description VM"
}  

   
# Einfuehrungsseiten

output "README" {
  value = templatefile( "INTRO.md", { ip = join(" ", module.lerncloud.*.ip_vm), fqdn = join(" ", module.lerncloud.*.fqdn_vm), ADDR = join(" ", module.lerncloud.*.ip_vm) } )
}

output "ACCESSING" {
  value = templatefile( "ACCESSING.md", { ip = join(" ", module.lerncloud.*.ip_vm), fqdn = join(" ", module.lerncloud.*.fqdn_vm), ADDR = join(" ", module.lerncloud.*.ip_vm) } )
}


