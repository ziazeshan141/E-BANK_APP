# 1. VPC Module
module "vpc" {
  source       = "./modules/vpc"
  environment  = var.environment
  vpc_cidr     = "10.0.0.0/16"
  cluster_name = var.cluster_name
}

# 2. Security Group Module
module "security_group" {
  source      = "./modules/security_group"
  environment = var.environment
  vpc_id      = module.vpc.vpc_id
  vpc_cidr    = module.vpc.vpc_cidr
}

# 3. ECR Module
module "ecr_frontend" {
  source          = "./modules/ecr"
  environment     = var.environment
  repository_name = "ebank-frontend"
}

module "ecr_node_backend" {
  source          = "./modules/ecr"
  environment     = var.environment
  repository_name = "ebank-node-backend"
}

module "ecr_django_backend" {
  source          = "./modules/ecr"
  environment     = var.environment
  repository_name = "ebank-django-backend"
}

# 4. IAM Module (OIDC Pod Roles + kubectl IAM Admin Role)
module "iam" {
  source               = "./modules/iam"
  cluster_name         = var.cluster_name
  oidc_provider_arn    = module.eks.oidc_provider_arn
  namespace            = "default"
  service_account_name = "app-service-account"
}

# 5. EKS Module (Cluster + OIDC Provider + Access Entries for kubectl)
module "eks" {
  source           = "./modules/eks"
  cluster_name     = var.cluster_name
  environment      = var.environment
  vpc_id           = module.vpc.vpc_id
  private_subnets  = module.vpc.private_subnets
  additional_sg_id = module.security_group.security_group_id

  # Connects the IAM Admin role to Kubernetes via AWS Access Entries
  access_entries = {
    kubectl_admin = {
      kubernetes_groups = []
      principal_arn     = module.iam.kubectl_admin_role_arn

      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }
}