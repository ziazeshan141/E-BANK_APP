resource "aws_vpc_peering_connection" "ec2_to_eks" {
  vpc_id      = var.ec2_vpc_id
  peer_vpc_id = var.eks_vpc_id
  auto_accept = true

  tags = {
    Name        = "${var.environment}-ec2-to-eks-peering"
    Environment = var.environment
  }
}

# Explicit accepter - ensures the connection actually transitions to "active"
# rather than sitting at "pending-acceptance" (this was your earlier bug)
resource "aws_vpc_peering_connection_accepter" "accept" {
  vpc_peering_connection_id = aws_vpc_peering_connection.ec2_to_eks.id
  auto_accept                = true

  tags = {
    Name = "${var.environment}-ec2-to-eks-peering-accepter"
  }
}

resource "aws_route" "ec2_to_eks" {
  for_each = {
    for idx, route_table_id in var.ec2_route_table_ids :
    tostring(idx) => route_table_id
  }

  route_table_id            = each.value
  destination_cidr_block    = var.eks_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.ec2_to_eks.id

  depends_on = [aws_vpc_peering_connection_accepter.accept]
}

resource "aws_route" "eks_to_ec2" {
  for_each = {
    for idx, route_table_id in var.eks_private_route_table_ids :
    tostring(idx) => route_table_id
  }

  route_table_id            = each.value
  destination_cidr_block    = var.ec2_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.ec2_to_eks.id

  depends_on = [aws_vpc_peering_connection_accepter.accept]
}

# Allow EC2 VPC to reach the EKS API (443) over the peering connection
resource "aws_security_group_rule" "allow_ec2_vpc_to_eks_api" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [var.ec2_vpc_cidr]
  security_group_id = var.eks_cluster_security_group_id
  description       = "Allow EC2 bastion VPC to reach EKS API via peering"
}