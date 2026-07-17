# 008 -- Update to catalog schema v6 (holdings signal) + adopt the current module

> Filed from the libcat framework repo (cross-repo note, uncommitted): the
> framework moved ahead of this demo. Left uncommitted so a session working in
> this repo owns whether/when to pick it up.

## Why (build is currently broken)

Against the current libcat Hugo module the demo **fails to build**:

```
ERROR libcat: catalog.json schema version 5, module targets 6 --
reproject with a matching lcat (tasks/009)
Error: error building site: logged 1 error(s)
```

The projector/module advanced to **schema v6** while this repo still emits
**v5**. v6 added the **holdings signal** -- `Work.Held` / `Instance.Held`:
physical items, or a live-availability identifier whose feed still lists the
Work (libcat tasks/078). `assets/catalog.json` and `assets/facets.json` are
both `version: 5`, and works have no `held` field, so the module's version guard
rejects the build.

(Local dev resolves the module via the `replace => ../libcat/hugo` in
`go.mod`, so this bites immediately on a local `hugo` build, not just deploy.)

## Options to regenerate at v6

1. **Preferred -- switch to the real `lcat` pipeline.** libcat now ships a
   first-party **Hardcover ingest source** (`libcat/ingest/hardcover/`,
   framework tasks/026) and a `Held` signal the projector fills. Retire the
   hand-rolled JS pipeline (`scripts/fetch-hardcover.mjs`, `scripts/gen-facets.mjs`)
   in favour of Hardcover -> BIBFRAME grains -> `lcat project`, which emits
   `catalog.json` + `facets.json` at the current schema automatically. This is
   what 018's scope point 2 called the preferred path ("flow through the real
   BIBFRAME -> lcat project pipeline rather than a one-off transform"), it keeps
   facet counts correct from the projector, and it means the next schema bump is
   a re-run, not a hand-edit.
2. **Quick unbreak (stopgap).** Bump the JS pipeline: `fetch-hardcover.mjs:266`
   `version: 5` -> `6` (and its header comment), the version in
   `gen-facets.mjs`, and populate a `held` value on each work/instance. Cheaper
   now, but keeps hand-maintaining schema the module owns -- expect to redo it on
   the next bump.

## Holdings-signal semantics for a read-shelf demo

Decide what `Held` means for "books Eve has read": there's no live-availability
feed here, so the projector's default (feed-present or physical item) won't
trigger. Simplest defensible choice: mark every demo Work `held` (the conceit is
that Eve's Library owns them), so the module's holdings indicator renders.
Confirm how the current module surfaces `Held` and pick a value that reads
honestly for a demo.

## Also worth a pass (module moved since the last sync, ~Jul 2)

The module gained a patron dark-mode toggle, a refreshed "library-ish but
modern" default theme identity, and the holdings indicator. Rebuild and eyeball
these against this repo's `assets/lcat.css` / `layouts/` overrides -- shadowed
templates can drift from new module markup. Availability stays **off** by design
(the DAIA physical-ILS adapter that just landed upstream is not needed here).

## Deploy pin

`scripts/pin-module.sh` swaps the local `replace` for a published module version
in CI/deploy. Once `github.com/freeeve/libcat/hugo` is tagged at a version
that includes the v6 module, bump the pin (tasks/003) so the deployed build
matches local.

## Resolution (2026-07-04)

Took **option 1 (real `lcat` pipeline)** and the **honest `held`** reading:

- **Pipeline.** Retired the Node scripts (`fetch-hardcover.mjs`, `map-subjects.mjs`,
  `gen-facets.mjs`) and `data/subject-map.json`. `npm run data:refresh` now runs
  `scripts/refresh-data.sh` = `lcat hardcover --out build/` then
  `lcat project --provider hardcover --out assets/` against the sibling
  `../libcat` checkout. Schema version, controlled subjects, facet counts, and the
  holdings signal are projector-owned now; the next bump is a re-run. Regenerated 102
  works / 262 instances at **schema v6** (parity with the old v5 corpus: 101 covers, 95
  with subjects, 13 subjects, rating on 97). Projection is deterministic and work IDs are
  stable across runs.
- **`held` semantics.** The current module ships **no** holdings-indicator template
  ("renders unheld works unchanged; badging is the site's choice"), and the projector
  honestly computes `held: false` for a read-shelf (no `overdrive-reserve` feed, no
  physical `bf:hasItem`). So `held` is absent from the JSON and no badge renders -- the
  honest outcome for "books Eve has read." No fabricated `held: true`, no demo badge.
- **Theme/overrides.** Diffed this repo's shadowed `baseof.html` against the module base
  -- only the documented `EVL+` superset lines differ (still valid; the module's new
  empty `head-extra.html`/`footer.html` hooks are superseded here). Verified in a real
  browser (headless Chrome, light + dark via emulated `prefers-color-scheme`): theme
  identity, dark-mode toggle, covers, subjects, and `print`/`ebook`/`audiobook` formats
  all render. Fixed the one stale data reference: the JSON-LD format map in
  `seo.html` (`physical` -> `print`, the projector's canonical BIBFRAME vocabulary).
- **Deploy pin.** Unblocked: `github.com/freeeve/libcat/hugo` is now tagged
  `hugo/v0.1.0` (contains the v6 module) and pushed. Fixed `scripts/pin-module.sh`, which
  was broken for this repo -- the demo imports the module only as a *Hugo* module (no Go
  package imports it), so the old `go get` + `go mod tidy` failed on the placeholder
  `v0.0.0` require and would have pruned the require entirely. It now does
  `go mod edit -dropreplace -require=@<ver>` + `go mod download`. Verified end-to-end:
  `pin-module.sh v0.1.0` -> `hugo --minify` builds clean against the proxy-fetched module.
  Remaining step is external: set the CI repo variable `HUGO_MODULE_VERSION = v0.1.0`
  (consumed at `.github/workflows/deploy.yml:48`) so the next deploy pins to it.

## Acceptance

- `hugo --minify` builds clean against the current module (no schema-version
  error); `npm run build:full` (with Pagefind) succeeds.
- `catalog.json` + `facets.json` are `version: 6` with a sensible `held` signal;
  facet counts match the corpus (regenerated, not hand-tallied).
- Dark mode, holdings indicator, and the current theme render correctly with
  this repo's overrides.
- Deploy pin updated to a published module version once one exists.
