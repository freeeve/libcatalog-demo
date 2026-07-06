# Read-only lcatd cataloging demo. Front door is CloudFront + a Lambda Function URL,
# provisioned by the readonly-demo module in cloudfront.tf (tasks/010, migrated off API
# Gateway). This file holds the shared LCATD_* env the module consumes, the us-east-1 ACM
# certificate, and the Route 53 alias pointing at CloudFront. Writes are rejected by the
# backend (read-only blob store + HTTP 403 guard), so public exposure is safe.

locals {
  # Consumed by module.demo (cloudfront.tf). Grains extract to /var/task/grains on Lambda.
  lambda_env = merge(
    {
      # Sandbox implies read-only: the editor shows Save and renders each edit as if
      # committed (dry-run doc), wiped on refresh -- nothing persists (tasks/011).
      LCATD_SANDBOX  = "1"
      LCATD_BLOB_DIR = "/var/task/grains"
      # Bundled snapshots so existing subjects render real headings: lcsh (corpus
      # subset; live search proxies id.loc.gov via /v1/vocabsuggest) and homosaurus
      # (FULL vocabulary -- the picker searches all ~3.9k terms locally, tasks/020).
      LCATD_VOCAB_SCHEMES     = "lcsh,homosaurus"
      LCATD_LOCAL_AUTH        = "1"
      LCATD_BOOTSTRAP_ADMIN   = var.demo_admin
      LCATD_LOCAL_SIGNING_KEY = var.local_signing_key
      LCATD_PROVIDER          = var.provider_name
    },
    var.abuse_secret == "" ? {} : { LCATD_ABUSE_SECRET = var.abuse_secret }
  )
}

# --- Custom domain: ACM cert (us-east-1, DNS-validated) that CloudFront serves the alias
# with. CloudFront requires the cert in us-east-1 -- this stack's region.
resource "aws_acm_certificate" "cert" {
  domain_name       = var.domain
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  zone_id         = var.hosted_zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]
}

# --- DNS: alias the custom domain at the CloudFront distribution (module.demo).
# Z2FDTNDATAQYW2 is CloudFront's fixed hosted-zone id for alias records.
resource "aws_route53_record" "alias" {
  zone_id = var.hosted_zone_id
  name    = var.domain
  type    = "A"
  alias {
    name                   = module.demo.cloudfront_domain
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}
