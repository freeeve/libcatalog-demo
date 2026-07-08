variable "aws_region" {
  description = "Region for the S3 origin bucket (CloudFront/ACM are pinned to us-east-1 separately)."
  type        = string
  default     = "us-east-1"
}

variable "domain_name" {
  description = "Public hostname for the demo."
  type        = string
  default     = "libcat.evefreeman.com"
}

variable "bucket_name" {
  description = "S3 origin bucket name (private; served only via CloudFront OAC). Bucket names are immutable, so changing this replaces the bucket; the site is re-synced from a build afterwards (contents are disposable)."
  type        = string
  default     = "libcat-evefreeman-com-site"
}

variable "manage_dns" {
  description = <<-EOT
    When true, Terraform creates the ACM DNS-validation records and the A/AAAA alias
    in the Route 53 hosted zone below. Set false if evefreeman.com DNS lives elsewhere;
    then create the printed validation CNAME and an alias/ANAME to the distribution by
    hand.
  EOT
  type        = bool
  default     = true
}

variable "hosted_zone_id" {
  description = "Route 53 hosted zone id for evefreeman.com (required when manage_dns = true)."
  type        = string
  default     = ""
}

variable "github_repo" {
  description = "owner/name of the GitHub repo allowed to assume the deploy role via OIDC."
  type        = string
  default     = "freeeve/libcat-demo"
}

variable "create_oidc_provider" {
  description = <<-EOT
    Create the GitHub Actions OIDC provider. Set false if the AWS account already has a
    token.actions.githubusercontent.com provider (only one per account is allowed); the
    deploy role then references the existing one.
  EOT
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default = {
    Project = "libcat-demo"
    # AWS tag values disallow apostrophes ([\p{L}\p{Z}\p{N}_.:/=+\-@]*), so no "Eve's".
    Site = "Eves Library"
  }
}
