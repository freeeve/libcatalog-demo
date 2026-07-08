# Deploy: sandbox cataloging demo (lcatd on Lambda)

The companion to the static catalog (tasks/009): a public `lcatd` instance so visitors
can explore the *cataloging* side of libcat -- the editor, review queue, copy
cataloging, profiles -- not just the finished catalog. Live at
https://try.libcat.evefreeman.com.

Runs in **sandbox mode** (`LCATD_SANDBOX=1`, tasks/011): a visitor can edit a record and
watch the change render (materialized from the dry-run), search all of LCSH in the subject
picker (live from `id.loc.gov`), and see existing subjects with real headings -- but
sandbox implies read-only, so the grain store is wrapped read-only and every write is
403'd. Nothing persists; a page refresh (or Lambda cold start) resets everything. See
libcat `backend/deploy/README.md` and tasks/097, 011.

## Shape (cheapest tier)

One arm64 Lambda (`provided.al2023`) serving the libcat backend with the cataloging
SPA embedded and the BIBFRAME grains **bundled in the zip** -- in-memory document store,
so **no DynamoDB and no S3**. Fronted by **CloudFront + a Lambda Function URL** (tasks/010,
via the libcat `readonly-demo` module): CloudFront edge-caches the SPA's hashed
`/assets/*` so page loads don't wake Lambda, and a Function URL has no per-request charge.
Scale-to-zero: ~$0 when idle. The grains are the same corpus as the static catalog (this
repo's `build/data/works`, from `npm run data:refresh`, tasks/008).

```
Lambda (bootstrap + grains/ + embedded SPA)  <-  Function URL  <-  CloudFront  <-  try.libcat.evefreeman.com
  LCATD_SANDBOX=1, in-memory store, grains at /var/task/grains          edge-caches /assets/*; /config + /v1/* pass through
```

## Layout

- `build.sh` -- builds `dist/lcatd-demo.zip`: `npm run build` the SPA (libcat
  tasks/098), `go build` the arm64 `bootstrap` from `../libcat/backend/cmd/lcatd-lambda`,
  bundle `grains/` (works from this repo's `build/`, plus the LCSH snapshot below).
  Requires a sibling `../libcat` checkout.
- `lcsh.nq` + `gen-lcsh.sh` -- the corpus-sized LCSH authority snapshot bundled at
  `grains/data/authorities/vocab/lcsh.nq` so the editor renders existing subjects' real
  headings (`LCATD_VOCAB_SCHEMES=lcsh`, tasks/011). `gen-lcsh.sh` regenerates it via
  `lcat vocab-subset` (needs internet); re-run when the catalog's subjects change.
- `terraform/` -- `cloudfront.tf` wires the libcat `readonly-demo` module (Lambda +
  Function URL + CloudFront, `?ref=backend/v0.3.0`); `main.tf` holds the shared `LCATD_*`
  env, the us-east-1 ACM cert, and the Route 53 alias -> CloudFront. Secrets in a
  gitignored `terraform.tfvars`.
- `deploy.sh` -- `build.sh`, then generate/reuse a stable signing key, then
  `terraform apply`.

## Deploy

```
AWS_PROFILE=deeplibby-admin deploy/lcatd/deploy.sh              # review plan, approve
AWS_PROFILE=deeplibby-admin deploy/lcatd/deploy.sh -auto-approve
```

First apply validates the ACM cert via DNS and provisions the CloudFront distribution
(the distribution takes a few minutes to deploy). Redeploy after a data refresh or module
bump by re-running `deploy.sh` (the zip's `source_code_hash` change triggers a Lambda code
update; HTML is served fresh so it shows immediately, and `/assets/*` hashes change so they
never go stale; the signing key is preserved).

## Configuration (terraform variables)

Non-secret vars have sensible defaults (`variables.tf`): `domain`
(`try.libcat.evefreeman.com`), `demo_admin` (`demo@example.org:readonlydemo` -- read-only,
safe to publish), `provider_name` (`hardcover`), `region` (`us-east-1`). Lambda memory
(cold-start lever) is the module's `memory_size` default (1024). Secrets go in the
gitignored `terraform.tfvars`, written by `deploy.sh`:

- `hosted_zone_id` -- Route 53 zone for evefreeman.com.
- `local_signing_key` -- base64 Ed25519 seed; **stable** so demo sessions survive Lambda
  cold starts / concurrent instances. `openssl rand -base64 32`.
- `abuse_secret` -- optional (>=16 bytes); only mounts anon suggest/export (writes still 403).

## Notes / caveats

- **Sandbox, nothing persists.** Sandbox mode shows Save and renders an edit from the
  dry-run's materialized doc, but writes are still rejected twice -- the blob store returns
  `ErrReadOnly` and the HTTP guard 403s mutating methods (except allow-listed auth and
  dry-run). Verified: `POST /v1/publish` -> 403 (authed and unauthed); a refresh/cold start
  resets everything.
- **In-memory store + cold starts.** Concurrent Lambda instances have separate in-memory
  stores, so a session's *refresh* can miss across instances; the stable signing key
  keeps the access token valid, so re-login is the worst case. The store resets on cold
  start -- desirable for a demo.
- **LCSH.** Live subject search proxies to `id.loc.gov` (`/v1/vocabsuggest`, no local
  load -- the Lambda has outbound internet). Existing subjects resolve to real headings
  from the bundled `lcsh.nq` snapshot (`LCATD_VOCAB_SCHEMES=lcsh`). The demo's catalog uses
  https LCSH URIs, so the snapshot is realigned to https to match (see `gen-lcsh.sh` and
  libcat tasks/100).
- **Writable production** (persistent DynamoDB + S3) is out of scope here -- see
  libcat tasks/099 and `backend/deploy/terraform` (the writable reference stack).
