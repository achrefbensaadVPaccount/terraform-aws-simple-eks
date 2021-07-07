output "worker_role_arn" {
  value = aws_iam_role.worker_role.arn
}

output "public_subnets_ids" {
  value = local.public
}

output "cluster_subnets_ids" {
  value = local.eks_subnets
}

# Left as it is for backward compatibility
output "private_subnet_ids" {
  value = local.private
}

output "oidc_identity_provider_issuer" {
  value = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}
