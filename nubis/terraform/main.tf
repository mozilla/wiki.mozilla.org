provider "aws" {
  region = "${var.region}"
}

module "worker" {
  source            = "github.com/nubisproject/nubis-terraform//worker?ref=v2.3.0"
  region            = "${var.region}"
  environment       = "${var.environment}"
  account           = "${var.account}"
  service_name      = "${var.service_name}"
  purpose           = "webserver"
  ami               = "${var.ami}"
  elb               = "${module.load_balancer.name}"
  ssh_key_file      = "${var.ssh_key_file}"
  ssh_key_name      = "${var.ssh_key_name}"
  nubis_sudo_groups = "${var.nubis_sudo_groups}"
  nubis_user_groups = "${var.nubis_user_groups}"
  instance_type     = "${var.environment == "prod" ? "m3.medium" : "t2.small"}"
  health_check_type = "ELB"                                                        # EC2 or ELB
  min_instances     = "${var.environment == "prod" ? 5 : 3}"

  # CPU utilisation based autoscaling
  scale_down_load = 30
  scale_up_load   = 60
}

module "load_balancer" {
  source               = "github.com/nubisproject/nubis-terraform//load_balancer?ref=v2.3.0"
  region               = "${var.region}"
  environment          = "${var.environment}"
  account              = "${var.account}"
  service_name         = "${var.service_name}"
  health_check_target  = "HTTP:80/?redirect=0"
  ssl_cert_name_prefix = "${var.service_name}"
  health_check_timeout = 5
}

module "dns" {
  source       = "github.com/nubisproject/nubis-terraform//dns?ref=v2.3.0"
  region       = "${var.region}"
  environment  = "${var.environment}"
  account      = "${var.account}"
  service_name = "${var.service_name}"
  target       = "${module.load_balancer.address}"
}

module "database" {
  source                 = "github.com/nubisproject/nubis-terraform//database?ref=v2.3.0"
  region                 = "${var.region}"
  environment            = "${var.environment}"
  account                = "${var.account}"
  monitoring             = true
  service_name           = "${var.service_name}"
  client_security_groups = "${module.worker.security_group}"
  allocated_storage      = 40
  multi_az               = true
  instance_class         = "${var.environment == "prod" ? "db.r3.large" : "db.t2.large"}"
  nubis_sudo_groups      = "${var.nubis_sudo_groups},team_dbeng"
}

module "cache" {
  source                 = "github.com/nubisproject/nubis-terraform//cache?ref=v2.3.0"
  region                 = "${var.region}"
  environment            = "${var.environment}"
  account                = "${var.account}"
  service_name           = "${var.service_name}"
  client_security_groups = "${module.worker.security_group}"
}

module "storage" {
  source                 = "github.com/nubisproject/nubis-terraform//storage?ref=v2.3.0"
  region                 = "${var.region}"
  environment            = "${var.environment}"
  account                = "${var.account}"
  service_name           = "${var.service_name}"
  storage_name           = "${var.service_name}"
  client_security_groups = "${module.worker.security_group}"
}

module "mail" {
  source       = "github.com/nubisproject/nubis-terraform//mail?ref=v2.3.0"
  region       = "${var.region}"
  environment  = "${var.environment}"
  account      = "${var.account}"
  service_name = "${var.service_name}"
}

module "backup" {
  source       = "github.com/nubisproject/nubis-terraform//bucket?ref=v2.3.0"
  region       = "${var.region}"
  environment  = "${var.environment}"
  account      = "${var.account}"
  service_name = "${var.service_name}"
  purpose      = "backup"
  role         = "${module.worker.role}"
}
