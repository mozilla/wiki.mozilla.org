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
  elb               = "${module.load_balancer.name}"
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

module "load_balancer" {
  source               = "github.com/nubisproject/nubis-terraform//load_balancer?ref=v2.4.3"
  region               = "${var.region}"
  environment          = "${var.environment}"
  account              = "${var.account}"
  service_name         = "${var.service_name}"
  health_check_target  = "HTTP:80/?redirect=0"
  ssl_cert_arn         = "${data.aws_acm_certificate.wiki.arn}"
  health_check_timeout = 5
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
  instance_class         = "${var.environment == "prod" ? "db.r5.large" : "db.t2.large"}"
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
