# 014 -- Content + correctness review; README refresh; more how-to content

Review the site's prose (README, `content/docs/*`, `content/about.md`) for staleness
against what libcatalog and this repo actually do today, fix what's wrong, and add
how-to content where the docs have gaps.

## Findings to fix (correctness)

- `README.md`: says schema version **5** (v6 since tasks/008); "Data" section documents
  the retired Node pipeline (`data:fetch` / `data:build` no longer exist in
  `package.json`); "Follow-up work" lists only tasks 001-005; no mention of the live
  cataloging sandbox (try.libcatalog.evefreeman.com), events/docs/CMS sections, or CI
  deploy; "(eventually) light branding overrides" -- branding shipped long ago.
- `content/docs/build-and-deploy.md`: step 2 tells readers to run `npm run data:build`
  (retired); pipeline description is the old fetch->map->facets shape instead of
  `lcat hardcover` -> `lcat project`; doesn't say the refresh needs the sibling
  `../libcatalog` checkout.
- `content/docs/theming.md`: shadow example cites `layouts/_partials/work-card.html`,
  which no longer exists (module renders covers natively via `covers = true`;
  upstream tasks/022+025 landed). Point at a real current shadow/partial instead.

## Content additions (how-to)

- New docs guide covering the cataloging sandbox (what lcatd is, what to try at
  try.libcatalog, how nothing persists) -- the About page covers "what", docs lack the
  "how".
- New docs guide: use your own data (Hardcover shelf -> your own catalog), lifted from
  scripts/README.md into reader-facing form.

## Verify

- `npm run build:full`; a11y audit `node ../libcatalog/hugo/a11y_audit.js public`;
  cross-check feature claims against the sibling checkout inventory.

## Outcome

Done. README rewritten (schema v6, real lcat pipeline, both tiers incl. the
try.libcatalog sandbox, CI deploy, current repo shape). build-and-deploy.md step 2 now
documents `lcat hardcover` -> `lcat project` (retired `data:build` reference removed).
theming.md rewritten around today's reality: module default theme incl. built-in
light/dark + toggle, token re-branding as the option (not this site's setup), the
head-extra/footer/hero injection hooks, and baseof.html as the one real remaining
shadow (work-card.html shadow no longer exists). baseof.html's stale "Hugo has no
footer/head hook" comment corrected. Two new guides: docs/use-your-own-data.md
(Hardcover/MARC/OverDrive sources, ingest->project shape) and
docs/cataloging-sandbox.md (hands-on lcatd tour); cross-links from
build-and-deploy.md and running-it.md. Clean already: scripts/README.md, about.md,
docs/_index.md, how-it-works.md, running-it.md, events. Verified: build:full + axe
audit over 504 pages, 0 violations; new pages render.
