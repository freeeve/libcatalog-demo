# 011 -- Richer cataloging demo: sandbox editing + working LCSH subjects

> Filed from the libcat framework repo (cross-repo note, uncommitted). Left
> uncommitted so a session working in this repo owns whether/when to pick it up.

## Status (2026-07-05): DONE

Live at https://try.libcat.evefreeman.com/. Flipped the demo Lambda's env from
`LCATD_READ_ONLY=1` to **`LCATD_SANDBOX=1`** (implies read-only) and added
`LCATD_VOCAB_SCHEMES=lcsh`; bundled a corpus-sized LCSH snapshot at
`grains/data/authorities/vocab/lcsh.nq`. CloudFront/Function-URL infra (010) unchanged --
`terraform apply` was a single in-place Lambda update (new zip + env).

- **Sandbox**: `/config` now reports `sandbox:true` (+ `readOnly:true`); the editor shows
  Save and renders edits from the dry-run doc, reset on refresh. Writes still 403.
- **Live LCSH search**: verified `GET /v1/vocabsuggest?source=lcsh&q=science%20fiction`
  returns live id.loc.gov headings (Lambda has outbound internet) -- no local vocab load.
- **Existing subjects resolve**: `GET /v1/terms/resolve` returns real headings
  ("Fiction", "Fantasy fiction") for the catalog's subjects.

Scheme gotcha: the demo's catalog uses **https** LCSH URIs (upstream ingest subject-map),
but `lcat vocab-subset`/id.loc.gov emit the **http** canonical, and the vocab index matches
URIs exactly -- so the raw snapshot reported "0 terms" and wouldn't resolve. `gen-lcsh.sh`
realigns the snapshot to https to match the catalog. Filed the tool fix as libcat
tasks/100. Scope point 3 (static-catalog labels) was already satisfied -- `catalog.json`
subjects already carry en/es labels inline. Copy updated on the About page.

NOTE: the About-page copy change is committed but the **static site needs a redeploy**
(push to main -> CI) to publish it; the cataloging demo itself is already live.

## Why

`009` shipped a read-only cataloging demo. libcat now supports a fuller,
interactive demo without giving up "nothing persists" -- three new capabilities
(all verified upstream):

1. **Sandbox editing** (`LCATD_SANDBOX=1`, implies read-only): the record editor
   shows Save and renders each edit as if committed (from the dry-run's
   materialized doc), wiped on a page refresh. Nothing is written.
2. **Live LCSH subject search** works out of the box: the built-in `lcsh` source
   proxies to `id.loc.gov` (`/v1/vocabsuggest`), so the subject picker
   autocompletes all of LCSH with **no local vocab load** -- the Lambda just
   needs outbound internet (it has it).
3. **`lcat vocab-subset`**: builds a corpus-sized authority snapshot so the
   demo's *existing* LCSH subjects render their real headings instead of
   `shNNNN "not in local index"`.

## Scope

1. **Flip to sandbox.** Set `LCATD_SANDBOX=1` (drop `LCATD_READ_ONLY`; sandbox
   implies it). Visitors can now edit records and watch the change render, then
   refresh to reset.
2. **Bundle the LCSH subset for display.** From the projected catalog:
   ```sh
   lcat vocab-subset --catalog build/catalog.json --out lcsh.nq
   ```
   Place it at `grains/data/authorities/vocab/lcsh.nq` (bundled in the Lambda
   zip) and set `LCATD_VOCAB_SCHEMES=lcsh`. Small file -> negligible cold-start
   cost. This fixes the "not in local index" chips in the editor.
3. **Public-site labels (optional but nice).** Reproject with the subset loaded
   so `catalog.json` carries the resolved subject labels too, and the static
   catalog shows real headings, not bare URIs.
4. **Copy.** Update the "cataloging demo" blurb: "search LCSH, edit a record --
   your changes render but reset on refresh; nothing is saved."

## Notes

- Needs the libcat version carrying these features (backend sandbox +
  dry-run-doc; the `lcat vocab-subset` subcommand in the root module). Pin the
  demo's libcat checkout / module refs accordingly.
- Known upstream edge: a raw client that *executes* (non-dry-run) an edit against
  a read-only/sandbox instance gets a 500 (blocked at the blob store) rather than
  a clean 403; the sandbox UI only ever dry-runs, so it is unreachable in normal
  use.
- The CloudFront/Function-URL module (demo `010`) is unchanged -- only the env
  (`LCATD_SANDBOX`, `LCATD_VOCAB_SCHEMES`) and the bundled `lcsh.nq` differ.

## Acceptance

- The demo lets a visitor edit a record and see it render (then reset on
  refresh), search LCSH in the subject picker, and see existing LCSH subjects
  with real labels. Nothing persists (a bounce shows a pristine store).
