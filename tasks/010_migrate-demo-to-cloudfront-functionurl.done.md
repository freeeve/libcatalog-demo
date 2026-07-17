# 010 -- Migrate the read-only demo from API Gateway to CloudFront + Function URL

> Filed from the libcat framework repo (cross-repo note, uncommitted). Left
> uncommitted so a session working in this repo owns whether/when to pick it up.

## Status (2026-07-04): DONE

Migrated `try.libcat.evefreeman.com` from API Gateway v2 to **CloudFront + Lambda
Function URL** via the libcat `readonly-demo` module
(`?ref=backend/v0.3.0`), reusing the same zip, grains, `LCATD_*` env, and us-east-1 ACM
cert (front-door only; no code/env/grain change). `deploy/lcatd/terraform/cloudfront.tf`
adds the module; `main.tf` now holds just the shared env, cert, and the Route 53 alias
(-> CloudFront); the API Gateway resources + the old Lambda are gone.

Two-phase, zero-downtime cutover: Phase 1 stood up CloudFront alongside the live API GW
(5 add, verified on the `*.cloudfront.net` domain), Phase 2 repointed the alias and
destroyed the API GW + old Lambda (1 change, 11 destroy). **Verified live**: `/config` ->
`readOnly:true`, `POST /v1/publish` -> 403, login + dashboard render 102 works, response
carries `via: ...cloudfront.net`, and `/assets/*` go Miss->Hit at the edge while
`/config` + `/v1/*` pass through uncached. Cheaper (no API GW per-request charge) and
faster (edge-cached assets don't wake Lambda). Teardown/redeploy unchanged
(`deploy/lcatd/deploy.sh`; `terraform destroy`).

## Why

`009` is live at https://try.libcat.evefreeman.com/ on **Lambda + API Gateway
v2**. libcat `backend/v0.3.0` now ships a turnkey module for a *cheaper and
more responsive* front door -- **Lambda Function URL + CloudFront** -- backing the
same Lambda, grains, and env. Two wins over API Gateway:

- **Cost.** A Function URL has no per-request charge (API Gateway HTTP API is
  $1.00/M after its 12-month free window). For a demo that's the difference
  between "free forever" and "cheap".
- **Responsiveness.** CloudFront edge-caches the SPA's hashed `/assets/*`, so a
  page renders from the edge **without waking Lambda** -- the cold start is only
  felt on the first API call. API Gateway has no such caching in this setup.

The Lambda, the bundled grains, and all `LCATD_*` env stay identical; only the
edge/front-door changes.

## The module

`github.com/freeeve/libcat//backend/deploy/terraform/modules/readonly-demo?ref=backend/v0.3.0`
provisions the arm64 Lambda, a public Function URL, and a CloudFront distribution
wired with the correct cache split (hashed `/assets/*` cached hard; `/config` +
`/v1/*` never cached, forwarded all-viewer-except-Host; HTML served fresh). See
its README for the consumer block and `build-zip.sh` (SPA + bootstrap + grains).

## Steps

1. **ACM cert in us-east-1.** CloudFront requires the alias cert in **us-east-1**
   (API Gateway's cert is likely in the deploy region). Request/validate a
   `try.libcat.evefreeman.com` cert in us-east-1 (DNS-validated via Route 53).
2. **Swap the terraform** in `deploy/lcatd/terraform`: replace the API-GW +
   lambda resources with the module block, reusing the existing grains-bundled
   zip (the current `deploy.sh` build, or the module's `build-zip.sh`), the same
   `environment`, `aliases = ["try.libcat.evefreeman.com"]`, and
   `acm_certificate_arn` = the us-east-1 cert. Keep the stable
   `LCATD_LOCAL_SIGNING_KEY` (gitignored tfvars) so warm sessions survive, and
   `LCATD_VOCAB_SCHEMES` trimmed for a faster cold start.
3. **`terraform apply`** -> note the `cloudfront_domain` output.
4. **Repoint DNS.** Move the Route 53 alias for `try.libcat.evefreeman.com`
   from the API-GW domain to the CloudFront distribution.
5. **Verify live:** assets come from the edge (`x-cache: Hit from cloudfront`, no
   Lambda invocation), `/config` -> `readOnly:true` and `/v1/*` pass through,
   sign-in + banner + 102 works still render, `POST /v1/publish` -> 403. Watch
   the first-API-call `Init Duration` in the Lambda's CloudWatch logs -- that is
   now the only place the cold start shows.
6. **Remove the old API Gateway** resources once CloudFront is serving.

## Non-goals

- No change to the Lambda code, grains, or `LCATD_*` env -- this is purely the
  edge/front-door.
- Writable production (DynamoDB/S3 + worker model) stays out of scope (libcat
  `tasks/099`).

## Acceptance

- `try.libcat.evefreeman.com` is served through CloudFront + a Lambda Function
  URL; SPA assets are edge-cached; the old API Gateway is gone.
- The demo still passes 009's checks (sign-in, read-only banner, 102 works,
  writes 403), and page loads no longer wake Lambda for static assets.
