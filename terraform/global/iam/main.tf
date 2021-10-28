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
      name = "iam"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "cwa_server_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "4.2.0"

  create_role             = true
  create_instance_profile = true
  role_name               = "CloudWatchAgentServerRole"
  role_requires_mfa       = false

  trusted_role_services = [
    "ec2.amazonaws.com"
  ]

  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
  ]
}
