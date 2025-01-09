# main.tf

# ---------------------------------------------------------------------
# Specify Terraform version (optional but recommended)
# ---------------------------------------------------------------------
terraform {
  required_version = ">= 1.0.0"
  # We will configure the backend after creating the S3 bucket,
  # so for now, it remains local.
}

# ---------------------------------------------------------------------
# AWS Provider Configuration
# ---------------------------------------------------------------------
provider "aws" {
  region = "us-east-1"
  # If you're using aws configure credentials,
  # Terraform should pick them up automatically.
}

# ---------------------------------------------------------------------
# Resource: Create S3 Bucket
# ---------------------------------------------------------------------
resource "aws_s3_bucket" "terraform_state_store" {
  bucket = "my-terrform-bucket-vsm524565-19985245"  # Bucket name must be globally unique
  acl    = "private"
  
  tags = {
    Name        = "TerraformStateBucket"
    Environment = "DevOpsProject"
  }
}

