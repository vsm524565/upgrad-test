output "s3_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state_store.bucket
}

output "vpc_id" {
  value       = aws_vpc.main_vpc.id
  description = "The ID of the new VPC."
}

output "private_subnet_a_id" {
  value       = aws_subnet.private_a.id
  description = "Subnet A ID."
}

output "private_subnet_b_id" {
  value       = aws_subnet.private_b.id
  description = "Subnet B ID."
}

output "nat_gateway_id" {
  value       = aws_nat_gateway.nat_gw.id
  description = "NAT Gateway ID."
}
output "bastion_public_ip" {
  description = "Public IP of the Bastion"
  value       = aws_instance.bastion.public_ip
}

output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = aws_lb.public_alb.dns_name
}

