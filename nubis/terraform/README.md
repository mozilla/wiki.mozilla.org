

# Working with Terraform

## Set Up

Before you deploy with Terraform you need to set up your terraform.tfvars file.
There is an example copy called terraform.tfvars-dist that you can copy and
edit. It should look something like this:

```

account = "nubis-lab"
region  = "us-west-2"
environment = "stage"
service_name = "skel"
ami="ami-XXXX"

```

### account

This is the name for the AWS account you are intending to deploy to.

### region

The AWS region you wish to deploy to, like us-east-1 or us-west-2

### environment

The environment is one of *sandbox*, *stage* or *prod*. For this (and all manual
deployments) you will set this to *sandbox*.

### service_name

The service_name is the name of this service. For Mozilla deployments this
should be the name of a real service as noted in [inventory](https://inventory.mozilla.org/en-US/core/service/)

### ami

You will collect this as output from nubis-builder. Once the build is complete
nubis-builder will display the ami id which you will need to manually copy into
the terraform.tfvars file. You will need to do this after every successful build.

### ssh_key_file

Path to the public ssh key file you want authorized to ssh into the launched
instances

### ssh_key_name

The account unique name you want to give to that ssh key

## Commands to work with Terraform

NOTE: All examples run from the nubis/terraform directory.

In these examples the service name is called *nubis-skel*. You will need to
choose a unique service name for your deployment as their can only be one
*nubis-skel* deployment at a time in one account.

### Get

Get and update dependent terraform modules

```

$> terraform get -update=true

```

### Plan

Preview the proposed change

```

$> terraform Plan

```

### Apply

Apply the proposed change

```

$> terraform apply

```

### Login

If you have only one EC2 instance and your ssh keys are on the jumphost, you can
login by:

```bash

ssh -A -t ec2-user@jumphost.<env>.<region>.<account-name>.nubis.allizom.org \
"ssh -A -t ubuntu@<service_name>.service.consul

```

### Visit site

Terraform creates a route53 hosted zone and a cname record. And the resulting
url will be part of the outputs:

```

Outputs:

  address = https://www.<service_name>-<env>.<env>.<region>.<account_name>.nubis.allizom.org/

```

### Delete

To delete the deployment:

```

$> terraform destroy

```
