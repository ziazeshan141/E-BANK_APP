variable "cluster_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnets" {
  type = list(string)
}

variable "additional_sg_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "access_entries" {
  description = "Access entries mapping IAM roles/users to Kubernetes permissions"
  type        = any
  default     = {}
}