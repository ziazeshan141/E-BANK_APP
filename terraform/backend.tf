terraform {
  backend "s3" {
    bucket       = "state-locking-047385030300-us-east-2-an"
    key          = "ebank-eks/terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
    use_lockfile = true
  }
}