
# Allgemeine Variablen

# Public Variablen

variable "module" {
    type    = string
    default = "base"
}

variable "userdata" {
    description = "Cloud-init Script"
    default = "/../../modules/base.yaml"
}

variable "ports" {
    type    = list(number)
    default = [ 22, 80 ]
}

# Scripts

data "template_file" "userdata" {
  template = file(var.userdata)
}
