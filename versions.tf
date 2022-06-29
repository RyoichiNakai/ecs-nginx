# Providerのバージョンを指定
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.19.0"
    }
  }
}

provider "aws" {
  # Configuration options
  region                   = var.region
  shared_credentials_files = var.shared_credentials_files
  profile                  = var.profile
}
