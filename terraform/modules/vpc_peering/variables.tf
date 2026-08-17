variable "ec2_vpc_id" {
  description = "VPC ID where the EC2 bastion lives"
  type        = string
}

variable "eks_vpc_id" {
  description = "VPC ID where the EKS cluster lives"
  type        = string
}

variable "ec2_vpc_cidr" {
  description = "CIDR block of the EC2 VPC"
  type        = string
}

variable "eks_vpc_cidr" {
  description = "CIDR block of the EKS VPC"
  type        = string
}

variable "ec2_route_table_ids" {
  description = "Route table IDs in the EC2 VPC that need a route to the EKS VPC"
  type        = list(string)
}

variable "eks_private_route_table_ids" {
  description = "Private route table IDs in the EKS VPC that need a route to the EC2 VPC"
  type        = list(string)
}

variable "eks_cluster_security_group_id" {
  description = "EKS cluster security group ID (control plane SG) to allow inbound 443 from EC2 VPC"
  type        = string
}

variable "environment" {
  description = "Environment name for tagging"
  type        = string
}