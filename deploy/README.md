# Deploy: S3 + CloudFront

Static hosting for https://libcatalog.evefreeman.com (tasks/003). Private S3 origin,
CloudFront with Origin Access Control + TLS, a viewer-request function for Hugo pretty
URLs, and a branded 404. CI deploys via GitHub OIDC -- no long-lived AWS keys.

## Layout

- `terraform/` -- the infrastructure (S3, CloudFront, ACM, optional Route 53, the CI
  deploy role). See `terraform/variables.tf` for inputs.
- `deploy.sh` -- sync a built `public/` to S3 with content-types + cache headers and
  invalidate CloudFront. Used by CI and runnable locally.
- `../.github/workflows/deploy.yml` -- build + deploy on push to `main`.
- `../scripts/pin-module.sh` -- swap the local module `replace` for a published version.

## One-time bootstrap

1. **Provision infra.** With AWS credentials that can manage S3/CloudFront/ACM/IAM
   (and Route 53 if `manage_dns = true`):

   ```
   cd deploy/terraform
   terraform init
   terraform apply -var 'hosted_zone_id=Z...'      # omit + set manage_dns=false for external DNS
   ```

   If DNS is external, set `-var 'manage_dns=false'`, then create the printed ACM
   validation CNAME and an alias/ANAME for the domain to the `distribution_domain_name`
   output. CloudFront only goes ACTIVE once the cert validates.

2. **Publish the module.** CI has no `../libcatalog` checkout, so the `replace` in
   `go.mod` must be dropped and a **published** version required. Tag the module in the
   libcatalog repo (e.g. `git tag hugo/v0.1.0 && git push origin hugo/v0.1.0`), then set
   `HUGO_MODULE_VERSION` below. Local dev keeps the `replace`; `pin-module.sh` only runs
   in CI, so nothing local leaks into the deployed build.

3. **Wire CI** from the Terraform outputs. Repo → Settings → Secrets and variables →
   Actions:

   | Kind     | Name                          | Value                          |
   |----------|-------------------------------|--------------------------------|
   | Variable | `AWS_REGION`                  | e.g. `us-east-1`               |
   | Variable | `AWS_DEPLOY_ROLE_ARN`         | `deploy_role_arn` output       |
   | Variable | `S3_BUCKET`                   | `bucket_name` output           |
   | Variable | `CLOUDFRONT_DISTRIBUTION_ID`  | `distribution_id` output       |
   | Variable | `HUGO_VERSION`                | e.g. `0.148.2`                 |
   | Variable | `HUGO_MODULE_VERSION`         | e.g. `v0.1.0`                  |
   | Secret   | `HARDCOVER_API_TOKEN` (optional)  | enables the scheduled refresh  |

## Deploying

- **Automatic:** push to `main`. The workflow pins the module, optionally refreshes data
  from Hardcover, builds + Pagefind-indexes, then runs `deploy.sh`.
- **Manual (one command)** from a machine with AWS creds:

  ```
  npm run build:full
  BUCKET=<bucket> DISTRIBUTION_ID=<id> bash deploy/deploy.sh
  ```

## Caching

`deploy.sh` sets: Pagefind assets (content-addressed) `immutable` for a year; other
static assets one day; HTML + sitemap 300s `must-revalidate`; the manifest gets an
explicit `application/manifest+json` type. CloudFront compresses on the fly, so no
pre-gzip step is needed. Every deploy invalidates `/*`.
