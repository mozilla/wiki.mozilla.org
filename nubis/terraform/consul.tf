# Discover Consul settings
module "consul" {
  source       = "github.com/nubisproject/nubis-terraform//consul?ref=v1.5.0"
  region       = "${var.region}"
  environment  = "${var.environment}"
  account      = "${var.account}"
  service_name = "${var.service_name}"
}

# Configure our Consul provider, module can't do it for us
provider "consul" {
  address    = "${module.consul.address}"
  scheme     = "${module.consul.scheme}"
  datacenter = "${module.consul.datacenter}"
}

# Publish our outputs into Consul for our application to consume
resource "consul_keys" "config" {
  key {
    name   = "cache_port"
    path   = "${module.consul.config_prefix}/MemCachedPort"
    value  = "${module.cache.endpoint_port}"
    delete = true
  }

  key {
    name   = "cache_endpoint"
    path   = "${module.consul.config_prefix}/MemCachedEndpoint"
    value  = "${module.cache.endpoint_host}"
    delete = true
  }
}
