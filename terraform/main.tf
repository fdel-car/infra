terraform {
  required_providers {
    aws = {
      source : "hashicorp/aws",
      version : "3.51.0"
    }
  }
  backend "remote" {
    organization = "strapi"

    workspaces {
      name = "shared-infra"
    }
  }
}

locals {
  tags = {
    Terraform   = true
    Environment = "staging"
  }
}

provider "aws" {
  region = var.aws_region
  assume_role {
    role_arn = "arn:aws:iam::024762031643:role/terraform-shared-infra"
  }
}

module "network" {
  source = "./modules/network"

  aws_region = var.aws_region
}

module "permissions" {
  source = "./modules/permissions"
}

resource "aws_sns_topic" "alarm_notifications" {
  name = "alarm-notifications-topic"
}

resource "aws_sns_topic_subscription" "alarm_notifications_subscription" {
  topic_arn = aws_sns_topic.alarm_notifications.arn
  protocol  = "email"
  endpoint  = "fabien.delcarmen@strapi.io" // Should be replaced by infra@strapi.io
}
