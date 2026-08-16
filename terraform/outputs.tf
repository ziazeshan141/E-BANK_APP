output "vpc_id" {
  description = "The VPC ID"
  value       = module.vpc.vpc_id
}

output "eks_cluster_name" {
  description = "EKS Cluster Name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS Control Plane Endpoint"
  value       = module.eks.cluster_endpoint
}

output "ecr_frontend_url" {
  value = module.ecr_frontend.repository_url
}
output "ecr_node_backend_url" {
  value = module.ecr_node_backend.repository_url
}
output "ecr_django_backend_url" {
  value = module.ecr_django_backend.repository_url
}

output "kubectl_admin_role_arn" {
  description = "IAM Role ARN to assume for kubectl access"
  value       = module.iam.kubectl_admin_role_arn
}

output "irsa_role_arn" {
  description = "IAM Role ARN for Pod OIDC authentication"
  value       = module.iam.irsa_role_arn
}