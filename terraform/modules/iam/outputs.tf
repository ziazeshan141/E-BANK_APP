output "irsa_role_arn" { value = module.irsa_role.iam_role_arn }
output "kubectl_admin_role_arn" { value = aws_iam_role.eks_admin.arn }