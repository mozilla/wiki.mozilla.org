provider "aws" {
  region = "${var.region}"
}

data "aws_acm_certificate" "wiki" {
  domain   = "${var.environment == "prod" ? "wiki.mozilla.org" : "wiki.allizom.org"}"
  statuses = ["ISSUED"]
}

module "worker" {
  source            = "github.com/nubisproject/nubis-terraform//worker?ref=v2.3.0"
  region            = "${var.region}"
  environment       = "${var.environment}"
  account           = "${var.account}"
  service_name      = "${var.service_name}"
  purpose           = "webserver"
  ami               = "${var.ami}"
  elb               = "${var.environment == "prod" ? "arn:aws:elasticloadbalancing:us-west-2:921547910285:loadbalancer/app/wiki-prod/ad49b7d565dd20f8" : "arn:aws:elasticloadbalancing:us-west-2:921547910285:loadbalancer/app/wiki-stage/59e998f857a6232c"}"
  ssh_key_file      = "${var.ssh_key_file}"
  ssh_key_name      = "${var.ssh_key_name}"
  nubis_sudo_groups = "${var.nubis_sudo_groups}"
  nubis_user_groups = "${var.nubis_user_groups}"
  instance_type     = "${var.environment == "prod" ? "m5.medium" : "t3.small"}"
  health_check_type = "ELB" # EC2 or ELB
  min_instances     = "${var.environment == "prod" ? 5 : 3}"

  # CPU utilisation based autoscaling
  scale_down_load = 30
  scale_up_load   = 60
}

module "dns" {
  source       = "github.com/nubisproject/nubis-terraform//dns?ref=v2.3.0"
  region       = "${var.region}"
  environment  = "${var.environment}"
  account      = "${var.account}"
  service_name = "${var.service_name}"
  target       = "${var.environment == "prod" ? "wiki-prod-850398177.us-west-2.elb.amazonaws.com" : "wiki-stage-309377030.us-west-2.elb.amazonaws.com"}"
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
  engine_version         = "5.7.38"
  parameter_group_name   = "${var.environment == "prod" ? "default.mysql5.7-db-omejnkmaq6skwy7hbu4pslhm34-upgrade" : "default.mysql5.7-db-ore5lzjf75p23t3z6x2qhenupy-upgrade"}"
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
