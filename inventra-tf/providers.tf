terraform {
  required_version = ">= 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  # TODO — Étape 2 : décommenter après avoir créé le bucket d'état
  # backend "s3" {
  #   bucket         = "inventra-tf-state-<ACCOUNT_ID>"
  #   key            = "inventra/terraform.tfstate"
  #   region         = "eu-west-1"
  #   dynamodb_table = "inventra-tf-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "Terraform"
    }
  }
}
