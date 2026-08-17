module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.35"

  vpc_id                   = var.vpc_id
  subnet_ids               = var.private_subnets
  control_plane_subnet_ids = var.private_subnets

  cluster_endpoint_public_access  = false
  cluster_endpoint_private_access = true

  # Enables OIDC Provider for IAM Roles for Service Accounts (IRSA)
  enable_irsa = true

  # Enables native EKS API Access Entries for kubectl IAM auth
  authentication_mode = "API_AND_CONFIG_MAP"
  
  # Auto-grants ClusterAdmin to the Terraform runner
  enable_cluster_creator_admin_permissions = true

  # Attach custom access entries
  access_entries = var.access_entries

  eks_managed_node_group_defaults = {
    instance_types = ["t3.medium"]
  }

  eks_managed_node_groups = {
    general = {
      min_size     = 1
      max_size     = 3
      desired_size = 2

      capacity_type          = "ON_DEMAND"
      vpc_security_group_ids = [var.additional_sg_id]
    }
  }

  tags = {
    Environment = var.environment
  }
}