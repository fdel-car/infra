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
      name = "tracker-staging"
    }
  }
}

provider "aws" {
  region = var.region
}

locals {
  environment = "staging"
}

data "terraform_remote_state" "vpc" {
  backend = "remote"

  config = {
    organization = "strapi"
    workspaces = {
      name = "vpc-${local.environment}"
    }
  }
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "6.5.0"

  name = "tracker-alb"

  load_balancer_type = "application"

  vpc_id          = data.terraform_remote_state.vpc.outputs.id
  subnets         = data.terraform_remote_state.vpc.outputs.public_subnets
  security_groups = [data.terraform_remote_state.vpc.outputs.default_security_group_id]

  http_tcp_listeners = [{
    port     = 80
    protocol = "HTTP"
  }]

  tags = {
    Terraform   = true
    Environment = local.environment
  }
}

module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "4.7.0"

  name = "tracker-asg"

  min_size            = 0
  max_size            = 1
  desired_capacity    = 1
  health_check_type   = "EC2"
  vpc_zone_identifier = data.terraform_remote_state.vpc.outputs.private_subnets

  # Launch template
  lt_name     = "tracker-lt-${local.environment}"
  description = "Launch template for the staging tracker."

  use_lt    = true
  create_lt = true

  image_id      = "ami-06d79c60d7454e2af" // Ubuntu 20.04 LTS amd64
  instance_type = "t2.micro"

  tags_as_map = {
    Terraform   = true
    Environment = local.environment
  }
}
