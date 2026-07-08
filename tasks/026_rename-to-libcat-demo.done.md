# 026: Rename libcatalog-demo -> libcat-demo (repo + subdomain)

The framework repo was renamed `libcatalog` -> `libcat` (libcat tasks/162):
GitHub `freeeve/libcat`, module paths `github.com/freeeve/libcat{,/hugo,...}`
from lockstep v0.25.0, local checkout `~/libcat`. This repo should follow.

## Broken right now (do first, independent of the rename)

- `go.mod` replace points at `../libcatalog/hugo`, which no longer exists
  (checkout is `~/libcat`) -- local Hugo builds fail until it points at
  `../libcat/hugo`.
- New hugo-module versions publish only under the new path: bump the require
  to `github.com/freeeve/libcat/hugo` (hugo/v0.26.0 adds the default
  cat-on-books brand mark + dark-aware SVG favicon; this site's shadowed
  partials/branding win over the defaults where present). Update
  `scripts/pin-module.sh` prose to match.

## Rename

- GitHub repo `freeeve/libcatalog-demo` -> `freeeve/libcat-demo` (old URL
  redirects); local dir `~/libcatalog-demo` -> `~/libcat-demo`; module line
  `github.com/freeeve/libcat-demo`.
- CI/OIDC gotcha: `deploy/terraform/variables.tf` pins the deploy role trust
  to `freeeve/libcatalog-demo` -- GitHub's OIDC sub claim carries the NEW repo
  name after a rename, so update the trust condition (and the
  `libcatalog-demo-deploy` role name if renaming for consistency) or deploys
  will fail auth.

## Subdomain

libcatalog.evefreeman.com -> libcat.evefreeman.com:

- `hugo.toml` baseURL; terraform: domain variable, CloudFront alias + ACM
  cert (new SAN or new cert), DNS record, function name
  `libcatalog-demo-rewrite`, distribution comment, Project tag.
- S3 bucket `libcatalog-evefreeman-com-site`: renaming a bucket means a new
  bucket + sync + repoint origin; keeping the old bucket name behind the new
  domain also works -- DECIDED 2026-07-08: keep the old bucket name (not
  user-visible; a rename buys nothing).
- ~~Keep the old subdomain alive as a 301 to the new one~~ -- DECIDED
  2026-07-08 (Eve): no keep-alive; the old subdomain simply goes away (apply
  removes its DNS records, the reissued cert covers only the new name).
  Links in libcat tags <= v0.24.0 READMEs will dangle -- accepted.
- Note: libcat's README (v0.25.0+) already links libcat.evefreeman.com (the
  rename sweep updated the URL), so that link dangles until this lands.

## Status 2026-07-08 -- APPLIED + VERIFIED

Scope grew mid-task (Eve): the sandbox subdomain moved too
(try.libcat.evefreeman.com), and the S3 bucket WAS renamed after all
(`libcat-evefreeman-com-site`; replace + re-sync, force_destroy now set since
contents are disposable deploy output). Old subdomains get no redirect.

Done + verified live: repo freeeve/libcat-demo; module paths/pin on
github.com/freeeve/libcat/hugo, CI pin v0.26.0 (schema v9 unchanged); both
terraform stacks applied under AWS_PROFILE=deeplibby-admin (new certs + DNS,
old libcatalog/try.libcatalog records gone, role libcat-demo-deploy, function
libcat-demo-rewrite, bucket swapped + site synced + invalidated); CI vars
AWS_DEPLOY_ROLE_ARN / S3_BUCKET / HUGO_MODULE_VERSION updated.
https://libcat.evefreeman.com/ 200, https://try.libcat.evefreeman.com/config
sandbox:true. deploy/terraform/terraform.tfvars (gitignored) now records
hosted_zone_id + create_oidc_provider=false for future plans.

Remaining: `mv ~/libcatalog-demo ~/libcat-demo` (user -- it is the session's
cwd).
