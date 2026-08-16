resource "aws_security_group" "app_sg" {
  name_prefix = "${var.environment}-app-sg-"
  description = "Custom Security Group for EKS App Workloads"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow intra-VPC TCP traffic"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-app-sg"
    Environment = var.environment
  }
}