terraform {
  required_providers {
    aws = {
      source : "hashicorp/aws",
      version : "3.51.0"
    }
  }
  backend "remote" {
    organization = "definitely-not-strapi"

    workspaces {
      name = "learning-infra"
    }
  }
}

provider "aws" {
  region = var.aws_region
  assume_role {
    role_arn = "arn:aws:iam::024762031643:role/TerraformLearningInfraRole"
  }
}

data "external" "what_is_my_ip" {
  program = ["/bin/bash", "${path.module}/what-is-my-ip.sh"]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.2.0"

  name = "vpc-${var.aws_region}-strapi-app-stack"
  cidr = "10.0.0.0/16"


  azs              = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  private_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets   = ["10.0.11.0/24", "10.0.12.0/24"]
  database_subnets = ["10.0.21.0/24", "10.0.22.0/24"]

  enable_nat_gateway   = false // It's expensive xD
  enable_dns_hostnames = true

  manage_default_security_group = true
  default_security_group_ingress = [{
    self        = true
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = format("%s/%d", data.external.what_is_my_ip.result["public_ip"], 32)
  }]
  default_security_group_egress = [{
    self        = true
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = "0.0.0.0/0"
  }]

  tags = {
    Terraform   = true
    Environment = "development"
  }
}

module "iam_assumable_role" {
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

data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = file("${path.module}/../config/public_keys/aws_rsa.pub")
  tags = {
    Terraform   = true
    Environment = "development"
  }
}

module "ec2_cluster" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "2.19.0"

  name           = "ee-registry"
  instance_count = 1

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.deployer.key_name
  iam_instance_profile   = module.iam_assumable_role.iam_instance_profile_name
  vpc_security_group_ids = [module.vpc.default_security_group_id]
  subnet_id              = module.vpc.public_subnets[0]

  tags = {
    Terraform   = true
    Environment = "development"
  }
}

resource "aws_sns_topic" "alarm_notifications" {
  name = "alarm-notifications-topic"
}

// I was just trying to understand how to enable multiple recipients for alert emails
locals {
  emails = ["fabien.delcarmen@strapi.io"]
}

resource "aws_sns_topic_subscription" "alarm_notifications_email_target" {
  count     = length(local.emails)
  topic_arn = aws_sns_topic.alarm_notifications.arn
  protocol  = "email"
  endpoint  = local.emails[count.index]
}

resource "aws_cloudwatch_metric_alarm" "ee_registry_disk_full" {
  alarm_name          = "ee-registry-disk-full"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "disk_free"
  namespace           = "CWAgent"
  period              = 120
  statistic           = "Average"
  threshold           = 4 * 1024 * 1024 * 1024 // Convert to gigabytes
  alarm_description   = "Monitors available disk space using CloudWatch agent"

  dimensions = {
    path   = "/"
    host   = format("ip-%s", replace(module.ec2_cluster.private_ip[0], ".", "-"))
    device = "xvda1"
    fstype = "ext4"
  }

  actions_enabled = true
  alarm_actions   = [aws_sns_topic.alarm_notifications.arn]
}

resource "aws_cloudwatch_metric_alarm" "ee_registry_high_cpu_load" {
  alarm_name          = "ee-registry-high-cpu-load"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Monitors EC2 CPU utilization"

  dimensions = {
    InstanceId = module.ec2_cluster.id[0]
  }

  actions_enabled = true
  alarm_actions   = [aws_sns_topic.alarm_notifications.arn]
}
