# variables.tf

variable "aws_region" {
  type        = string
  description = "AWS region where resources will be created"
  default     = "us-east-1"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "private_subnet_a_cidr" {
  type        = string
  description = "CIDR block for private subnet in AZ-a"
  default     = "10.0.1.0/24"
}

variable "private_subnet_b_cidr" {
  type        = string
  description = "CIDR block for private subnet in AZ-b"
  default     = "10.0.2.0/24"
}

variable "nat_eip_allocation_id" {
  type        = string
  description = "EIP allocation ID for NAT Gateway (can be created on-the-fly)"
  default     = ""
}

# If you want to specify availability zones, you can also define them:
variable "az_a" {
  type        = string
  description = "Primary availability zone"
  default     = "us-east-1a"
}

variable "az_b" {
  type        = string
  description = "Secondary availability zone"
  default     = "us-east-1b"
}

