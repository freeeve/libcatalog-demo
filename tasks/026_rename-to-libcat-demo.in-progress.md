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

## Status 2026-07-08 (session)

Done: go.mod/hugo.toml/pin-module.sh on the libcat paths; repo-wide
libcatalog->libcat sweep (bucket name + try.libcatalog sandbox domain kept);
terraform for the new domain/OIDC trust/function+role rename; GitHub repo
renamed to freeeve/libcat-demo (local remote repointed); CI
HUGO_MODULE_VERSION=v0.26.0; build + a11y audit green against ../libcat.

Remaining (user):
1. `cd deploy/terraform && terraform init && AWS_PROFILE=deeplibby-admin
   terraform plan` -- expect: cert reissue (new domain), distribution
   alias/comment update, function + deploy-role replacement (renames),
   old-domain A/AAAA replaced by libcat.evefreeman.com ones. Then `apply`.
2. `gh variable set AWS_DEPLOY_ROLE_ARN --body "$(terraform output -raw
   deploy_role_arn)"` (classifier-blocked for the session; CI deploys stay
   red until 1+2 land -- the OIDC sub claim already carries the new repo
   name).
3. Re-run the deploy workflow (or push) to publish to the new domain.
4. Rename the local dir: `mv ~/libcatalog-demo ~/libcat-demo` (left to the
   user -- it is this session's cwd).
5. Optional follow-up, out of scope here: the sandbox still lives at
   try.libcatalog.evefreeman.com (deploy/lcatd/terraform has its own domain
   config) -- decide whether it becomes try.libcat.evefreeman.com.
