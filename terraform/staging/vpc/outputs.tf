output "private_subnet_ids" {
  value       = module.vpc.private_subnets
  description = "List of IDs of the private subnets"
}
