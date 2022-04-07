

module "lerncloud" {
  #source     = "git::https://github.com/mc-b/terraform_lerncloud_aws.git"
  #source     = "git::https://github.com/mc-b/terraform_lerncloud_azure.git"
  #source     = "git::https://github.com/mc-b/terraform_lerncloud_maas.git"
  #source     = "git::https://github.com/mc-b/terraform_lerncloud_multipass.git"
  module     = "base"
  userdata   = "../modules/base.yaml"
}