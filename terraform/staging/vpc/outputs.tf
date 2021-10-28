output "id" {
  value       = module.vpc.vpc_id
  description = "The ID of the VPC"
}

output "public_subnets" {
  value       = module.vpc.public_subnets
  description = "List of IDs of the public subnets"
}

output "private_subnets" {
  value       = module.vpc.private_subnets
  description = "List of IDs of the private subnets"
}

output "private_subnets_cidr_blocks" {
  value       = module.vpc.private_subnets_cidr_blocks
  description = "List of cidr_blocks of private subnets"
}

output "private_subnets_ipv6_cidr_blocks" {
  value       = module.vpc.private_subnets_ipv6_cidr_blocks
  description = "List of IPv6 cidr_blocks of private subnets in an IPv6 enabled VPC"
}

output "default_security_group_id" {
  value       = module.vpc.default_security_group_id
  description = "The ID of the security group created by default on VPC creation"
}
