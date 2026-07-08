# Provider + version pinning for the Eve's Library static hosting stack (tasks/003).
# Two AWS providers: the default in the site's region for S3, and a us-east-1 alias
# because ACM certs for CloudFront and CloudFront itself are global/us-east-1.

terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.40"
    }
  }

  # Remote state is recommended so CI and local share one state. Fill in and uncomment:
  # backend "s3" {
  #   bucket = "evefreeman-tfstate"
  #   key    = "libcat-demo/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

provider "aws" {
  region = var.aws_region
}

# CloudFront ACM certificates MUST live in us-east-1 regardless of the site region.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
