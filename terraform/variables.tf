variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-2"
}

variable "environment" {
  description = "Deployment Environment"
  type        = string
  default     = "dev"
}

variable "cluster_name" {
  description = "EKS Cluster Name"
  type        = string
  default     = "my-modular-eks"
}

variable "vpc_cidr" {
  description = "CIDR block for the EKS VPC"
  type        = string
  default     = "10.1.0.0/16"
}

# --- EC2 bastion VPC details (for peering) ---
variable "ec2_vpc_id" {
  description = "VPC ID of the EC2 bastion VPC"
  type        = string
}

variable "ec2_vpc_cidr" {
  description = "CIDR block of the EC2 bastion VPC"
  type        = string
}

variable "ec2_route_table_ids" {
  description = "Route table IDs in the EC2 VPC needing a route to the EKS VPC"
  type        = list(string)
}