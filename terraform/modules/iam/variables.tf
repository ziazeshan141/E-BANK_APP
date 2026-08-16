variable "cluster_name" {
  type = string
}

variable "oidc_provider_arn" {
  type = string
}

variable "service_account_name" {
  type    = string
  default = "app-service-account"
}

variable "namespace" {
  type    = string
  default = "default"
}