locals {
  # Auto detect private and public subnets
  private_subnets_ids = [for subnet in data.aws_subnet.all_subnets : subnet.id if(subnet.map_public_ip_on_launch == false && subnet.assign_ipv6_address_on_creation == false)]
  public_subnets_ids  = setsubtract(toset(data.aws_subnet_ids.all_subnets_ids.ids), toset([for subnet in local.private_subnets_ids : subnet]))

  # Determine what subnets to use while building the cluster
  public      = var.cascading_subnets ? var.public_subnets : local.public_subnets_ids
  private     = var.cascading_subnets ? var.private_subnets : local.private_subnets_ids
  eks_subnets = var.allow_public_private_subnets ? setunion(local.public, local.private) : local.private

  # Log group name
  log_group_name = var.log_group_name == null ? var.cluster_name : var.log_group_name
}