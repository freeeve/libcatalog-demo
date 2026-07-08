# CloudFront + Lambda Function URL front door for the read-only demo (tasks/010),
# via the libcat turnkey module. Cheaper (no API Gateway per-request charge) and
# faster (CloudFront edge-caches the SPA's hashed /assets/* so page loads don't wake
# Lambda). Reuses the same zip, grains, env, and us-east-1 ACM cert as the API Gateway
# path; only the edge changes (task non-goal: no LCATD_* / code / grain changes).
#
# Migration is two-phase to avoid a broken window:
#   Phase 1 (this file): stand up CloudFront alongside the live API Gateway; DNS still
#     points at API GW. Verify via the *.cloudfront.net domain.
#   Phase 2 (main.tf edit): repoint the Route 53 alias to CloudFront and delete the API
#     Gateway resources + the old Lambda.
module "demo" {
  source     = "github.com/freeeve/libcat//backend/deploy/terraform/modules/readonly-demo?ref=v0.7.2"
  name       = "eves-library"
  lambda_zip = var.lambda_zip

  # Identical to the API Gateway Lambda's env (local.lambda_env, main.tf).
  environment = local.lambda_env

  aliases             = [var.domain]
  acm_certificate_arn = aws_acm_certificate_validation.cert.certificate_arn
}

output "cloudfront_domain" {
  description = "CloudFront distribution domain (Phase 2 points the Route 53 alias here)."
  value       = module.demo.cloudfront_domain
}

output "cloudfront_distribution_id" {
  value = module.demo.distribution_id
}
