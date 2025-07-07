terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

backend "s3" {
    bucket         = "reygasexpress-terraform-state"
    key            = "reygasexpress/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "reygasexpress-terraform-state-lock"
  }
}

provider "aws" {
  region = var.aws_region
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}