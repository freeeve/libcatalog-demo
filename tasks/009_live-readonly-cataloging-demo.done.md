# 009 -- Live read-only cataloging demo (lcatd with LCATD_READ_ONLY)

> Filed from the libcat framework repo (cross-repo note, uncommitted). Left
> uncommitted so a session working in this repo owns whether/when to pick it up.

## Status (2026-07-04): DONE -- live at https://try.libcat.evefreeman.com/

Hosting: **AWS Lambda + API Gateway v2 HTTP API** (scale-to-zero, ~$0 idle). The two
upstream blockers were resolved in libcat first:
- **`097` (done)** -- `cmd/lcatd-lambda` now calls `config.FromEnv` + the shared
  `appdeps.Build`, which gates the container-only worker tickers off in read-only mode.
- **`098` (done, filed by this session)** -- the release build now compiles the SPA
  before `go build`, so the embedded UI boots.

Deployed from this repo (`deploy/lcatd/`): a single arm64 Lambda serving the backend in
`LCATD_READ_ONLY=1`, cataloging SPA embedded, **BIBFRAME grains bundled in the zip**
(in-memory doc store -- no DynamoDB, no S3, IAM = logs only), fronted by an API Gateway
v2 HTTP API on `try.libcat.evefreeman.com` (ACM DNS-validated + Route 53). Grains are
the **same `lcat hardcover` output** as tasks/008 (`build/data/works/**.nq`) -- one ingest
feeds both the static catalog and the editor (102 works).

**Verified live**: `/config` -> `readOnly:true`; `POST /v1/publish` -> 403;
`demo@example.org` / `readonlydemo` signs in; the cataloging dashboard renders with the
read-only banner and 102 works (browser screenshot on the custom domain). Linked from the
site: an About-page section + a footer "Cataloging demo" link.

Redeploy: `AWS_PROFILE=deeplibby-admin deploy/lcatd/deploy.sh` (rebuilds the zip; Lambda
code updates on `source_code_hash` change; the signing key is preserved in the gitignored
tfvars). Teardown: `terraform destroy` in `deploy/lcatd/terraform`.

## Verified run-recipe (for when 097 unblocks the Lambda path)

Container form (what was verified; the Lambda form reuses the same env + grains once
`cmd/lcatd-lambda` wires `buildDeps`):

```
# 1. Build the SPA first (tasks/098) so the embedded UI boots, then the binary.
(cd ../libcat/backend/ui && npm ci && npm run build)
(cd ../libcat/backend && go build -o lcatd ./cmd/lcatd)   # or ./cmd/lcatd-lambda post-097

# 2. Grains = the tasks/008 ingest output (build/data/works/**.nq). For Lambda,
#    upload that tree to the LCATD_S3_BUCKET under the same data/works/ key layout.

# 3. Env (secrets -> SSM in the Lambda form):
LCATD_READ_ONLY=1
LCATD_BLOB_DIR=<grain dir>          # or LCATD_S3_BUCKET=<bucket> on Lambda
LCATD_LOCAL_AUTH=1
LCATD_LOCAL_SIGNING_KEY=<fixed base64 ed25519 seed>   # fixed so JWTs validate across cold starts
LCATD_BOOTSTRAP_ADMIN=demo@example.org:<demo password>
LCATD_PROVIDER=hardcover
# LCATD_ABUSE_SECRET=<32 bytes>     # optional; only mounts anon suggest/export (writes still 403)
```

Notes: in-memory doc store is fine (resets on restart -- desirable). Fixed signing
key is required so demo sessions survive Lambda cold starts / concurrent instances
(refresh tokens live in the per-instance mem store, so re-login may be needed across
instances -- acceptable for a demo). No `data/authorities/` was seeded, so vocab
panels read empty; seed `data/authorities/` too for a richer editor demo.

## Why

Eve's Library shows the **patron-facing output** of libcat: the static,
faceted, searchable catalog. It doesn't show the **cataloging side** -- the
editor, review queue, copy cataloging, editing profiles -- because that's a
running backend (`lcatd`), not a static site.

libcat now ships a **deployment-wide read-only mode** (`LCATD_READ_ONLY=1`,
released in `backend/v0.2.0`, libcat commit `cd99922`). It makes a public
`lcatd` safe to expose: the grain store is wrapped read-only and an HTTP guard
rejects editorial/config writes, so **nothing a visitor does persists to the
grains or config**, while sign-in, reads, external search, and **dry-run
previews** still work (you can edit a record and see the diff, just not save).
The SPA reads a `readOnly` flag from `/config` and shows a banner + hides the
Save/Publish affordances.

This task stands up such an instance so the demo covers both halves: browse the
finished catalog, then click "try the cataloging backend" and explore the admin
UI live.

## What read-only guarantees (so we can expose it publicly)

- Grains + blob-backed config (editing profiles, vocabulary snapshots, authority
  grains) are immutable (blob read-only decorator).
- Editorial/config writes (record/authority edits, review, publish, term
  governance, copycat staging/commit, profile edits, drafts, macros, merges)
  return 403.
- Auth, reads, copy-cataloging search, and dry-run previews work; the document
  store stays writable only for sessions/refresh tokens (no catalog state).

## Scope

1. **Deploy an `lcatd` container** with `LCATD_READ_ONLY=1` behind a subdomain
   (e.g. `try.libcat.evefreeman.com`, or a path off the demo). Persistence
   can be the simplest tier: in-memory document store + a local/mounted blob dir
   of pre-projected grains (resets on restart -- fine, even desirable, for a
   demo). DynamoDB/S3 (libcat `095`) only if durable demo state is wanted.
2. **Pre-seed the grains** the editor shows: project the same Eve's Library
   corpus (or a curated subset) into BIBFRAME grains under the blob dir, so the
   admin UI opens real records that match the public catalog. Reuse the Go
   ingest/project pipeline the static side now uses (this repo's `008`).
3. **Publish a demo credential.** Bootstrap a demo admin
   (`LCATD_BOOTSTRAP_ADMIN=demo@example.org:demo`) and show it on the site
   ("sign in as demo@example.org / demo") -- safe to share since read-only means
   no persistence.
4. **Reset cadence.** The writable document store only accumulates ephemeral
   scratch (staged drafts, queued review decisions); a periodic restart clears
   it. A scheduled bounce (or ephemeral container) keeps it tidy.
5. **Link from Eve's Library** (About page / footer): "This catalog was built
   with libcat -- try the cataloging backend that produced it."

## Considerations

- Public-instance hygiene: resource limits, and the built-in abuse/rate limiting
  (`LCATD_ABUSE_SECRET`) for the login/suggest paths.
- Known rough edge (libcat): the dry-run editor endpoints' *execute* path
  returns 500 (blocked at the blob store) rather than a clean 403 if a client
  bypasses the UI; the UI hides those buttons, so it only affects scripted
  callers. libcat may map it to 403 later.
- Same-origin: serve the SPA and API from one origin (lcatd already embeds the
  SPA and serves `/config`), so no CORS setup is needed.

## Acceptance

- A public URL where anyone signs in with the demo credential and explores the
  full cataloging UI (editor with dry-run diffs, review queue, copy cataloging,
  profiles) with a visible "read-only demo" banner.
- No action persists to grains or config (verified: edits/publishes 403; a
  restart shows a pristine store).
- Linked from the Eve's Library site.
