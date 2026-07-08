variable "region" {
  description = "AWS region for the Lambda + API Gateway (custom-domain ACM cert lives here too)."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Resource-name prefix."
  type        = string
  default     = "lcatd-demo"
}

variable "domain" {
  description = "Public hostname for the cataloging demo."
  type        = string
  default     = "try.libcat.evefreeman.com"
}

variable "hosted_zone_id" {
  description = "Route 53 hosted zone id for evefreeman.com (for ACM validation + the alias record)."
  type        = string
}

variable "lambda_zip" {
  description = "Path to the built deployment zip (bootstrap + bundled grains). See deploy/lcatd/build.sh."
  type        = string
  default     = "../dist/lcatd-demo.zip"
}

variable "provider_name" {
  description = "LCATD_PROVIDER surfaced in /config (matches the ingest source)."
  type        = string
  default     = "hardcover"
}

variable "demo_admin" {
  description = "LCATD_BOOTSTRAP_ADMIN as email:password. Read-only, so it is safe to publish; shown on the site."
  type        = string
  default     = "demo@example.org:readonlydemo"
}

variable "local_signing_key" {
  description = "LCATD_LOCAL_SIGNING_KEY -- base64 Ed25519 seed (32B). MUST be stable so demo sessions survive Lambda cold starts. Generate: openssl rand -base64 32."
  type        = string
  sensitive   = true
}

variable "abuse_secret" {
  description = "LCATD_ABUSE_SECRET (>=16 bytes). Optional; only mounts anon suggest/export (writes still 403). Empty = omit."
  type        = string
  default     = ""
  sensitive   = true
}
