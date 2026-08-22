terraform {
  required_version = ">= 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

# Single provider block. To point Terraform at LocalStack instead of the
# real AWS, copy local_override.tf.example -> local_override.tf (git-ignored).
# Terraform automatically merges *_override.tf files into matching blocks
# defined elsewhere, so there is never more than one active "aws" provider —
# no risk of a resource silently going to the wrong target because a
# provider alias was forgotten on it.
# https://developer.hashicorp.com/terraform/language/files/override
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

