# 013 -- Bump libcatalog to v0.4.2 (vocab-subset https fix; drop the band-aid)

> Filed from the libcatalog framework repo (cross-repo note, uncommitted). Left
> uncommitted so a session working in this repo owns whether/when to pick it up.

## Status (2026-07-05): DONE

Bumped the `readonly-demo` module ref `v0.4.1` -> **`v0.4.2`** (`cloudfront.tf`) and removed
the http->https rewrite band-aid from `deploy/lcatd/gen-lcsh.sh` -- stock
`lcat vocab-subset` (v0.4.2) now re-schemes in-namespace URIs to the catalog's https form,
so it writes **12 terms** (was "0 terms") and a resolving snapshot directly. Regenerated
`lcsh.nq` is **byte-identical** to the committed band-aid output, so no redeploy: the
terraform module is unchanged and the fix is in the `lcat` CLI (build tooling), not lcatd
(`terraform plan` = no changes). The deployed editor already resolves the subjects
("Fiction", etc., verified in 011/012). libcatalog `tasks/100` (the tool fix) is closed
upstream.

## Why

`011` worked around a bug in `lcat vocab-subset`: against this repo's **https**
LCSH catalog it wrote "0 terms" and a snapshot the index couldn't match, so the
demo rewrites the generated snapshot's `http://id.loc.gov/...` subject URIs to
`https://...` after generation.

Fixed upstream in **v0.4.2** (root `lcat`): `vocab-subset` now re-schemes
in-namespace URIs to the catalog's form, so an https catalog produces a resolving
snapshot directly. The post-generation rewrite is no longer needed.

## Steps

1. Bump the libcatalog checkout / `lcat` build to **v0.4.2** (the module `?ref`
   is already at v0.4.2 upstream; nothing else in v0.4.2 changed).
2. **Remove the http->https rewrite band-aid** from the snapshot build and run
   `lcat vocab-subset --catalog <catalog.json>
   --namespace https://id.loc.gov/authorities/subjects/ --out lcsh.nq` directly.
3. Rebuild the bundled `lcsh.nq`, redeploy, and confirm the editor still shows
   real LCSH headings (no "not in local index") and a non-zero term count.

## Acceptance

- The demo builds its LCSH subset with stock `lcat vocab-subset` (no manual URI
  rewrite) and the deployed editor resolves the subjects.
