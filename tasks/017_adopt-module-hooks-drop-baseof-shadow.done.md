# 017 -- Adopt libcat hugo/v0.5.0 hooks; drop the baseof shadow (zero shadows)

Upstream shipped our promotion asks (their tasks/118-120 -> hugo/v0.5.0): header
nav from `[[menu.main]]` + banner/brand hooks, default SEO head (lifted from this
site's partial), and the `.lcat-btn` component. This task makes good on 118's
promise: the demo now shadows **no module templates**.

## Changes

- **Deleted** `layouts/baseof.html` (the last shadow), `_partials/demo-banner.html`,
  `_partials/nav.html`, `_partials/head/seo.html`.
- **Added hook partials**: `banner.html` (demo ribbon, was demo-banner.html),
  `brand.html` (colophon + wordmark), `head-extra.html` (theme stylesheet +
  favicons/manifest/theme-color -- SEO/OG/JSON-LD now come from the module's
  head-seo.html, which was lifted from ours and is a superset).
- **Nav**: module renders it from the existing `[[menu.main]]` config; dropped the
  demo partial and the `.evl-nav`/`.evl-header` CSS (module owns `.lcat-nav`).
- **Buttons**: `evl-btn--light/--ghost/--solid` -> `lcat-btn--surface/--ghost/
  --solid` in home.html; dropped the `.evl-btn` CSS block; the 016 hero guard is now
  `:not(.lcat-btn)`.
- theming.md sections 4-5 updated: full hook list, "this site shadows nothing".

## Deliberate trade

The module <title> on the homepage is plain `site.Title` (ours appended the
tagline). Accepted the module default rather than keep a one-line shadow.

## Verify

Pinned build against published hugo/v0.5.0 (scripts/pin-module.sh) passes; CI
`HUGO_MODULE_VERSION` bumped v0.4.2 -> v0.5.0. build:full + axe audit clean.
Headless screenshots (light + dark): banner/brand/nav/buttons all render, hero
buttons legible in both modes.
