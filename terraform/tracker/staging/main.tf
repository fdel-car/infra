terraform {
  required_providers {
    aws = {
      source : "hashicorp/aws",
      version : "3.63.0"
    }
    hcp = {
      source  = "hashicorp/hcp"
      version = "0.20.0"
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

provider "hcp" {}

locals {
  environment = "staging"
}

data "terraform_remote_state" "vpc" {
  backend = "remote"

  config = {
    organization = "strapi"
    workspaces = {
      name = "vpc-internal-${local.environment}"
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

  target_groups = [
    {
      backend_protocol = "HTTP"
      backend_port     = 8080
      target_type      = "instance"
    }
  ]

  http_tcp_listeners = [{
    port     = 80
    protocol = "HTTP"
  }]

  tags = {
    Terraform   = true
    Environment = local.environment
  }
}

resource "aws_security_group" "instance_sg" {
  vpc_id = data.terraform_remote_state.vpc.outputs.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = data.terraform_remote_state.vpc.outputs.public_subnets_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Terraform   = true
    Environment = local.environment
  }
}

data "hcp_packer_iteration" "ubuntu" {
  bucket_name = "create-react-app"
  channel     = local.environment
}

data "hcp_packer_image" "ubuntu" {
  bucket_name    = "create-react-app"
  cloud_provider = "aws"
  iteration_id   = data.hcp_packer_iteration.ubuntu.ulid
  region         = var.region
}

module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "4.7.0"

  name = "tracker-asg"

  min_size            = 0
  max_size            = 1
  desired_capacity    = 1
  health_check_type   = "EC2" # Use "ELB" to have custom health check instead
  vpc_zone_identifier = data.terraform_remote_state.vpc.outputs.private_subnets

  target_group_arns = module.alb.target_group_arns

  # Launch template
  lt_name     = "tracker-lt-${local.environment}"
  description = "Launch template for the staging tracker."

  use_lt    = true
  create_lt = true

  image_id        = data.hcp_packer_image.ubuntu.cloud_image_id
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.instance_sg.id]

  user_date_64 = filebase64("./user_data.sh")

  tags_as_map = {
    Terraform   = true
    Environment = local.environment
  }
}
