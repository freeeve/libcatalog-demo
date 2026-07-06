# Eve's Library -- a libcatalog + Hugo demo

A public demo library site built with the [libcatalog](https://github.com/freeeve/libcatalog)
framework and its Hugo module, deployed at **https://libcatalog.evefreeman.com**. It shows
what an adopter gets on both tiers:

- **The static discovery site** (this repo): a normal library website -- homepage, events,
  docs -- with a full faceted catalog at `/works/`: one page per Work, controlled subjects
  (LCSH / Homosaurus) beside free tags, accessible multilingual-capable chrome, cover art,
  light/dark theme, and Pagefind full-text search. All static; no backend.
- **The cataloging backend** (`lcatd`), live as a public sandbox at
  **https://try.libcatalog.evefreeman.com** -- sign in as `demo@example.org` /
  `readonlydemo`, edit records, search LCSH; nothing persists.

This is a **demo of the framework, not a real library collection.** The catalog is Eve's
real *Read* shelf, sourced from Hardcover through the real `lcat` pipeline (see
`scripts/README.md`).

## How it works

This repo is a plain Hugo site that imports the libcatalog Hugo module the way any
adopter would (`hugo.toml` -> `[module].imports`) and mounts the projected data under
`assets/`:

- `assets/catalog.json` -- the Works (schema version 7).
- `assets/facets.json` -- precomputed facet value/counts.

The module supplies the catalog templates and assets; this repo provides config, data,
its own content sections (`content/events/`, `content/docs/`), and light `evl-*` branding
in `assets/lcat-theme.css` on top of the module's default theme. A Sveltia CMS scaffold
lives at `/admin/` (read-only until an OAuth backend is configured). The reader-facing
tour of all of this is on the site itself: [/docs/](https://libcatalog.evefreeman.com/docs/).

## Build

```
hugo --minify --destination public   # or: npm run build
npm run search:index                 # index public/ -> public/pagefind/ (Pagefind)
# or in one step:
npm run build:full
```

Then serve `public/` (locally: `hugo server`). Local builds resolve the module from a
sibling `../libcatalog` checkout via the `replace` in `go.mod`; CI pins a published
module version instead (`scripts/pin-module.sh`, repo var `HUGO_MODULE_VERSION`).

## Data

`assets/catalog.json` + `assets/facets.json` are produced by the real libcatalog
pipeline -- `lcat hardcover` (ingest the *Read* shelf into BIBFRAME grains) then
`lcat project` (project to the module's schema). Documented in `scripts/README.md`:

```
export HARDCOVER_API_TOKEN='...'   # Hardcover -> account settings -> API; never committed
npm run data:refresh               # lcat hardcover -> build/  then  lcat project -> assets/
```

Requires the sibling `../libcatalog` checkout. Never hand-edit the schema version or
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
