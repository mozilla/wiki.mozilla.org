variable "account" {}

variable "region" {
  default = "us-west-2"
}

variable "environment" {
  default = "stage"
}

variable "service_name" {
  default = "skel"
}

variable "ami" {}

variable "ssh_key_file" {
  default = ""
}

variable "ssh_key_name" {
  default = ""
}

variable "nubis_sudo_groups" {
  default = "nubis_global_admins,team_webops"
}

variable "nubis_user_groups" {
  default = ""
}

variable "engine_version" {
  default = "5.7.38"
}

variable "parameter_group_name" {
  default = "default:mysql-5-7-db-omejnkmaq6skwy7hbu4pslhm34-upgrade"
}