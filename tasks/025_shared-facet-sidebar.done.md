# 025 -- enable the shared facet sidebar (libcatalog tasks/150)

Filed from libcatalog (2026-07-06). libcatalog 862bda0 (main, in the local
`replace ../libcatalog/hugo` this repo already tracks) adds an opt-in shared
facet sidebar: instead of inlining the page-invariant sidebar into every
list/term page, the module publishes it once per language as a fingerprinted
fragment (`/lcat/facets.<lang>.<hash>.html`) fetched and inserted by
`lcat-sidebar.js`; pages ship a small host with localized no-JS fallback
links to the facet taxonomy landing pages.

This catalog is small, so the module README's guidance is to keep the inlined
default (no fetch, sidebar in the crawled HTML) -- but as the flagship demo
this site should showcase the feature and give it a second real deployment
before queerbooks (their tasks/011) leans on it at scale.

## Steps

1. `hugo.toml`: add
   ```toml
   [params.facets]
     shared = true
   ```
   (merge into the existing block if one exists by then).
2. Rebuild; confirm `/lcat/facets.<lang>.<hash>.html` publishes per language
   and term/list pages carry the host + fallback instead of the inlined nav.
3. Smoke in a browser: sidebar loads and the type-to-filter (and negatives,
   if this site enables them) hydrate over the fetched rows; with JS off the
   fallback taxonomy links render.
4. Deploy note: serve `/lcat/*.html` with the same
   `max-age=31536000,immutable` rule as the other fingerprinted assets --
   extension-based cache rules may miss a fingerprinted *.html*.
5. Mention the trade-off on the demo's README if it documents config: sidebar
   appears one fetch after first paint and leaves the crawled page HTML.

## Done (2026-07-06)

All five steps, verified against libcatalog 862bda0 via the local `replace`:

- `hugo.toml`: `[params.facets] shared = true` (new block; negatives stay off).
- Rebuilt: `/lcat/facets.en.<sha256>.html` publishes (9.5k, all six groups:
  LCSH, Homosaurus, Formats, Genres & tags, Languages, Contributors); list
  and term pages ship the host + SRI-fingerprinted `lcat-sidebar.<hash>.js`
  loader + no-JS fallback links (all six taxonomy landing pages exist).
  Pagefind does not index the fragment (no `data-pagefind-body`).
- Smoked end-to-end under jsdom over a live HTTP server: the loader fetched
  and inserted the fragment (fallback replaced), and the type-to-filter
  hydrated over the inserted rows (LCSH 12 rows -> 1 on "fantasy").
- `deploy/deploy.sh`: `lcat/*.html` now syncs `max-age=31536000,immutable`,
  excluded from the short-cache `*.html` rule -- exactly the extension-rule
  trap the task warned about.
- README: trade-off documented (also fixed schema-version drift, 7 -> 9).

Production note: 862bda0 is unreleased (no hugo tag past v0.21.1), so CI --
pinned to v0.21.1 -- ignores the unknown `shared` param and keeps inlining;
the config is inert until the next module release. When libcatalog tags it,
bump the `HUGO_MODULE_VERSION` repo variable and the feature goes live with
the cache rule already in place.
