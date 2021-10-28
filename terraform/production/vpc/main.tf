terraform {
  required_providers {
    aws = {
      source : "hashicorp/aws",
      version : "3.63.0"
    }
  }
  backend "remote" {
    organization = "strapi"

    workspaces {
      name = "vpc-production"
    }
  }
}

provider "aws" {
  region = var.region
}

locals {
  environment = "production"
}

data "aws_availability_zones" "all" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.2.0"

  name = "vpc-${local.environment}"
  cidr = "10.0.0.0/16"

  azs              = data.aws_availability_zones.all.names
  private_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets   = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  database_subnets = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]

  enable_nat_gateway   = false // Should be true but it's expensive
  enable_dns_hostnames = true

  manage_default_security_group  = true
  default_security_group_ingress = []
  default_security_group_egress = [{
    self        = true
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = "0.0.0.0/0"
  }]

  tags = {
    Terraform   = true
    Environment = local.environment
  }
}