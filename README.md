# Eve's Library -- a libcatalog + Hugo demo

A public demo catalog built with the [libcatalog](https://github.com/freeeve/libcatalog)
Hugo module. It shows what an adopter gets: one page per Work, faceted navigation, an
accessible multilingual-capable theme, and Pagefind full-text search -- all static, no
backend. Deployed at **https://libcatalog.evefreeman.com**.

This is a **demo of the framework, not a real library collection.** The catalog is
Eve's real *Read* shelf, sourced from Hardcover through a reproducible pipeline (see
`tasks/001` and `scripts/README.md`).

## How it works

This repo is a plain Hugo site that imports the libcatalog module the way any adopter
would (`hugo.toml` -> `[module].imports`) and mounts the projected data under `assets/`:

- `assets/catalog.json` -- the Works (schema version 5).
- `assets/facets.json` -- precomputed facet value/counts.

The module supplies every template and asset; this repo only provides config, data, and
(eventually) light branding overrides.

## Build

```
hugo --minify --destination public   # or: npm run build
npm run search:index                 # index public/ -> public/pagefind/ (Pagefind)
# or in one step:
npm run build:full
```

Then serve `public/` (locally: `hugo server`). Local builds resolve the module from a
sibling `../libcatalog` checkout via the `replace` in `go.mod`; CI pins a published
module version instead.

## Data

`assets/catalog.json` + `assets/facets.json` are produced by a reproducible pipeline
(`scripts/`, documented in `scripts/README.md`):

```
export HARDCOVER_API_TOKEN='...'   # Hardcover -> account settings -> API; never committed
npm run data:refresh           # fetch read shelf -> map controlled subjects -> regen facets
```

`data:fetch` needs `HARDCOVER_API_TOKEN`; `data:build` (subject mapping + facet regen)
runs over whatever `catalog.json` is present and is safe to re-run.

## Follow-up work

See `tasks/` -- the Hardcover data pipeline, generic-library branding, controlled-subject
mapping, S3 + CloudFront deploy, and quality/SEO passes.

## License

MIT -- Copyright (c) 2026 Eve Freeman.
