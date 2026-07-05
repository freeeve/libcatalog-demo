# 012 -- Bump libcatalog to v0.4.1 (read-only guard fix)

> Filed from the libcatalog framework repo (cross-repo note, uncommitted). Left
> uncommitted so a session working in this repo owns whether/when to pick it up.

## Status (2026-07-05): DONE

Bumped the `readonly-demo` terraform module ref `backend/v0.3.0` -> **`v0.4.1`**
(`deploy/lcatd/terraform/cloudfront.tf`) and rebuilt the Lambda zip from the sibling
checkout, which carries the guard fix (`backend/httpapi/readonly.go` allowlist now includes
`/marc/preview`, `/validate`, `/subjects/lookup` -- commit `e4b0a60`). The module itself is
unchanged in v0.4.1, so `terraform apply` was a single in-place Lambda update (0 add, 1
change, 0 destroy); no CloudFront/DNS change.

Verified live on `try.libcatalog.evefreeman.com` with a real work id: `subjects/lookup`
-> 200 (`{"candidates":[],...}`, not a read-only error), `marc/preview` -> 200 (returns the
MARC), `validate` -> 400 `empty patch` (reached the handler, i.e. past the guard -- was
403 before). Sandbox (`sandbox:true`) + LCSH from 011 unaffected; `POST /v1/publish` still
403.

## Why

The sandbox demo (`011`) is live, but a few editor actions return
**"read-only demo: changes are not saved"** even though they only *read*:

- "Load subjects at targets" (`POST /v1/works/{id}/subjects/lookup` -- reconcile
  subjects against external SRU/Z39.50 targets),
- MARC preview (`POST /v1/works/{id}/marc/preview`),
- Record validation (`POST /v1/works/{id}/validate`).

libcatalog's read-only/sandbox guard was 403'ing these because they are POSTs
outside its allowlist, even though none of them persist anything. Fixed
upstream in **v0.4.1** (they're now allowlisted alongside copycat search and the
dry-run endpoints).

## Steps

1. **Bump the pin to `v0.4.1`** everywhere the demo references libcatalog: the
   terraform module (`...readonly-demo?ref=v0.4.1`), and the libcatalog checkout
   the Lambda build compiles `cmd/lcatd` + `cmd/lcat` from.
2. **Rebuild the Lambda zip** (`build-zip.sh`, or the demo's `deploy/lcatd`
   build) from v0.4.1 so the deployed `lcatd` includes the fix.
3. **Redeploy** and verify in the live sandbox: "load subjects at targets"
   returns candidates (not a read-only error), and MARC preview / validate work.

## Acceptance

- In the deployed sandbox demo, subject lookup against targets, MARC preview,
  and validate all work; the sandbox editing + LCSH search from `011` are
  unaffected.

## Note

Nothing else in v0.4.1 changed (it's a targeted guard fix); the CloudFront
module, sandbox mode, and LCSH wiring from `010`/`011` are unchanged.
