# 003 -- Deploy to S3 + CloudFront (libcat.evefreeman.com)

## Status (DONE -- deployed and live)

`terraform apply` succeeded and the site is serving:
**https://libcat.evefreeman.com/** -> HTTP 200 over TLS, HTTP->HTTPS 301, deep
links resolve via the rewrite function, missing paths return the branded 404, Pagefind
assets load. Deployed with `deploy/deploy.sh` (staged cache headers + `/*` invalidation).
Account/zone/distribution identifiers live only in gitignored Terraform state, never
committed. CI (GitHub OIDC) still needs the module git-tagged before it can build; manual
`deploy.sh` works today.

Infra + tooling (all written, validated, and now applied):

- `deploy/terraform/` -- private S3 origin (OAC, no public website hosting), CloudFront
  (compression, managed caching + security-headers policies, `index.html` root, a
  viewer-request function for Hugo pretty URLs, 403/404 -> branded `/404.html`), ACM cert
  in us-east-1 with DNS validation, optional Route 53 alias (`manage_dns` toggle for
  external DNS), and a GitHub OIDC deploy role. `terraform validate` passes; `fmt` clean.
- `deploy/deploy.sh` -- staged S3 sync with per-class cache headers + correct
  content-types (Pagefind `immutable`, `.wasm` fixed, HTML short) + CloudFront
  invalidation. `bash -n` clean.
- `.github/workflows/deploy.yml` -- OIDC build+deploy on push to main, optional scheduled
  Hardcover refresh.
- `scripts/pin-module.sh` -- drops the local `replace` and pins a published module
  version so no local-only path leaks into CI (tasks §3).
- `layouts/404.html` -- branded not-found for the CloudFront error mapping.

To finish: publish/tag the module (`hugo/vX.Y.Z`), `terraform apply` with a hosted zone
(or external DNS), set the CI variables/secrets from the outputs (see `deploy/README.md`),
and push. The module has **no tags yet**, so pinning + CI build will fail until it is
tagged.

## Context

The demo is a static site; ARCHITECTURE §6 names S3 + CloudFront as the Tier 1 target.
This task stands up the hosting and a reproducible build+deploy pipeline.

## Inputs

- AWS account + credentials with S3, CloudFront, ACM, and (if DNS lives there) Route 53
  access.
- Control of `evefreeman.com` DNS to point `libcat` at CloudFront and validate the
  ACM cert.
- The GitHub repo (this one) for CI.

## Scope

1. **Infra (as code where practical -- Terraform/CloudFormation).**
   - S3 bucket for the site (private; served via CloudFront OAC, not public-website
     hosting).
   - CloudFront distribution: default root object `index.html`, compression on, sensible
     cache policy, and a **custom error / rewrite** so Hugo's `ugly`-free URLs and 404
     resolve (403/404 -> `/404.html` or a function that appends `index.html`).
   - ACM cert (us-east-1) for `libcat.evefreeman.com`; DNS validation.
   - Route 53 (or external DNS) A/AAAA alias -> the distribution.
2. **Build pipeline.**
   - `hugo --minify --destination public`
   - `pagefind --site public` (Pagefind index into `public/pagefind/`)
   - `aws s3 sync public/ s3://<bucket> --delete` (set correct `Content-Type`; Pagefind
     `.pf_*`/`.wasm`/`.pagefind` assets need proper types + long cache; HTML short cache)
   - CloudFront invalidation (`/*` or targeted paths).
3. **Module version pinning for CI.** The local `go.mod` `replace`s the module to a
   sibling checkout, which CI won't have. Before/at CI: remove the `replace` and require a
   **published** `github.com/freeeve/libcat/hugo` version (tag the module in the
   libcat repo, or use a pseudo-version). Document the bump step.
4. **CI (GitHub Actions).** On push to `main`: set up Hugo extended + Go, build, index,
   sync, invalidate. Store AWS creds via OIDC role (preferred) or repo secrets. Optionally
   run the Hardcover fetch (`tasks/001`) on a schedule to refresh content.

## Acceptance

- `https://libcat.evefreeman.com` serves the built, Pagefind-indexed site over TLS,
  with correct MIME types and working deep links / 404.
- A single CI run (or one documented command) builds and deploys from scratch.
- No local-only `replace` leaks into the deployed build; the module version is pinned.

## Refs

- ARCHITECTURE §6 (S3/CloudFront static tier). Pagefind post-build (libcat
  `tasks/017`, this repo's `npm run search:index`). Hugo Deploy / `aws s3 sync`.
