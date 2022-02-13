terraform {
  required_version = ">= 1.1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.74.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "3.1.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.1.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "2.1.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

provider "tls" {
  # Configuration options
}

provider "http" {
  # Configuration options
}

provider "random" {
  # Configuration options
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  vpc_summ        = "10.0.0.0/8"
  vpc0cidr        = "10.1.0.0/16"
  vpc1cidr        = "10.2.0.0/16"
  vpc2cidr        = "10.3.0.0/16"
  private_domain  = "corp.local"
  datacenter_cidr = "172.16.0.0/16" # This cannot be changed because it's hard-coded in the datacenter module
  az1             = data.aws_availability_zones.available.names[0]
  az2             = data.aws_availability_zones.available.names[1]
}

module "shared_services_vpc" {
  source = "./modules/shared-services-vpc"

  cidr = local.vpc0cidr
  az1  = local.az1
  az2  = local.az2
}

module "production_vpc" {
  source = "./modules/production-vpc"

  cidr = local.vpc1cidr
  az1  = local.az1
  az2  = local.az2

  allow_inbound = [
    {
      protocol = "icmp"
      from_port = -1
      to_port = -1
      source = local.datacenter_cidr
    }
  ]
}

module "development_vpc" {
  source = "./modules/development-vpc"

  cidr = local.vpc2cidr
  az1  = local.az1
  az2  = local.az2

  allow_inbound = [
    {
      protocol = "icmp"
      from_port = -1
      to_port = -1
      source = local.datacenter_cidr
    }
  ]
}

module "routing" {
  source = "./modules/routing"

  attachments = [
    {
      name            = "Shared Services"
      destination     = local.vpc_summ
      id              = module.shared_services_vpc.id
      subnets         = module.shared_services_vpc.subnets
      route_table     = module.shared_services_vpc.private_route_table
      shared_services = true
    },
    {
      name            = "Production"
      destination     = "0.0.0.0/0"
      id              = module.production_vpc.id
      subnets         = module.production_vpc.subnets
      route_table     = module.production_vpc.route_table
      shared_services = false
    },
    {
      name            = "Development"
      destination     = "0.0.0.0/0"
      id              = module.development_vpc.id
      subnets         = module.development_vpc.subnets
      route_table     = module.development_vpc.route_table
      shared_services = false
    }
  ]

  routes = [
    {
      destination = local.vpc_summ
      route_table = module.shared_services_vpc.public_route_table
    }
  ]
}

module "production_instances" {
  source = "./modules/instances"

  env     = "Production"
  subnets = [for subnet in module.production_vpc.subnets : { id : subnet, name : "Private${index(module.production_vpc.subnets, subnet)}" }]
}

module "development_instances" {
  source = "./modules/instances"

  env     = "Development"
  subnets = [for subnet in module.development_vpc.subnets : { id : subnet, name : "Private${index(module.development_vpc.subnets, subnet)}" }]
}

module "datacenter" {
  source = "./modules/datacenter"

  domain   = local.private_domain
  vpc_cidr = local.vpc_summ
  tgw = module.routing.tgw
  az1 = local.az1
  az2 = local.az2
}

module "resolver" {
  source = "./modules/resolver"

  domain = local.private_domain
  nameserver = module.datacenter.nameserver_ip
  target_vpc = {
    id = module.shared_services_vpc.id
    cidr = local.vpc0cidr
    subnets = module.shared_services_vpc.subnets
  }
  allowed_vpcs = [
    {
      id = module.production_vpc.id
      cidr = local.vpc1cidr
      name = "Production"
    }
  ]
}