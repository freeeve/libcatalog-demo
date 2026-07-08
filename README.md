# Eve's Library -- a libcat + Hugo demo

A public demo library site built with the [libcat](https://github.com/freeeve/libcat)
framework and its Hugo module, deployed at **https://libcat.evefreeman.com**. It shows
what an adopter gets on both tiers:

- **The static discovery site** (this repo): a normal library website -- homepage, events,
  docs -- with a full faceted catalog at `/works/`: one page per Work, controlled subjects
  (LCSH / Homosaurus) beside free tags, accessible multilingual-capable chrome, cover art,
  light/dark theme, and Pagefind full-text search. All static; no backend.
- **The cataloging backend** (`lcatd`), live as a public sandbox at
  **https://try.libcat.evefreeman.com** -- sign in as `demo@example.org` /
  `readonlydemo`, edit records, search LCSH; nothing persists.

This is a **demo of the framework, not a real library collection.** The catalog is Eve's
real *Read* shelf, sourced from Hardcover through the real `lcat` pipeline (see
`scripts/README.md`).

## How it works

This repo is a plain Hugo site that imports the libcat Hugo module the way any
adopter would (`hugo.toml` -> `[module].imports`) and mounts the projected data under
`assets/`:

- `assets/catalog.json` -- the Works (schema version 9).
- `assets/facets.json` -- precomputed facet value/counts.

The module supplies the catalog templates and assets; this repo provides config, data,
its own content sections (`content/events/`, `content/docs/`), and light `evl-*` branding
in `assets/lcat-theme.css` on top of the module's default theme. A Sveltia CMS scaffold
lives at `/admin/` (read-only until an OAuth backend is configured). The reader-facing
tour of all of this is on the site itself: [/docs/](https://libcat.evefreeman.com/docs/).

The facet sidebar uses the module's shared-fragment mode (`[params.facets] shared = true`):
instead of inlining the page-invariant sidebar into every list/term page, it is published
once per language as a fingerprinted fragment under `/lcat/` that a small loader fetches
and inserts. Trade-off: the sidebar appears one fetch after first paint and leaves the
crawled page HTML (no-JS readers get fallback links to the facet landing pages). A
catalog this small gains little -- it is enabled here to showcase the feature; small
catalogs should normally keep the inlined default.

## Build

```
hugo --minify --destination public   # or: npm run build
npm run search:index                 # index public/ -> public/pagefind/ (Pagefind)
# or in one step:
npm run build:full
```

Then serve `public/` (locally: `hugo server`). Local builds resolve the module from a
sibling `../libcat` checkout via the `replace` in `go.mod`; CI pins a published
module version instead (`scripts/pin-module.sh`, repo var `HUGO_MODULE_VERSION`).

## Data

`assets/catalog.json` + `assets/facets.json` are produced by the real libcat
pipeline -- `lcat hardcover` (ingest the *Read* shelf into BIBFRAME grains) then
`lcat project` (project to the module's schema). Documented in `scripts/README.md`:

```
export HARDCOVER_API_TOKEN='...'   # Hardcover -> account settings -> API; never committed
npm run data:refresh               # lcat hardcover -> build/  then  lcat project -> assets/
```

Requires the sibling `../libcat` checkout. Never hand-edit the schema version or
facet counts -- they are owned by the projector; re-run the refresh.

## Deploy

- **Static site**: S3 + CloudFront, defined in `deploy/terraform/`. Every push to `main`
  builds and deploys via GitHub Actions (OIDC, no stored secrets).
- **Cataloging sandbox**: a single scale-to-zero arm64 Lambda behind CloudFront, defined
  in `deploy/lcatd/` (`build.sh` bundles the SPA + grains into the zip; `LCATD_SANDBOX=1`,
  in-memory store, no database).

## Tasks

Work is tracked as numbered files in `tasks/` (status via rename: `.in-progress.md` /
`.done.md`), from the original data pipeline (001) onward.

## License

MIT -- Copyright (c) 2026 Eve Freeman.
