# 019 -- Bump to hugo/v0.6.0; drop the theme-toggle shadow and short-TTL cache stopgap

libcatalog hugo/v0.6.0 ships the fixes this site is carrying workarounds for
(libcatalog tasks/122 and 123):

- theme-toggle.html now pipes its jsonify'd labels through safeJS upstream, so
  the local shadow `layouts/_partials/theme-toggle.html` (the one-line quoted-label
  fix from tasks/018) can be deleted.
- lcat.css, lcat-search.js, and lcat-availability.js are now fingerprinted (content
  hash in the filename, SRI attributes included), so the deploy script's short-TTL
  cache headers for css/js can be replaced with `max-age=31536000,immutable` for
  the hashed assets.

Steps:

1. Bump the module: `hugo mod get github.com/freeeve/libcatalog/hugo@v0.6.0`
   (or update the go.mod require) and rebuild.
2. Delete `layouts/_partials/theme-toggle.html`; verify the toggle label renders
   without literal quotation marks after paint().
3. Update the deploy script's cache headers: hashed `lcat.*.css` / `lcat-*.js`
   assets get `max-age=31536000,immutable`; keep short TTLs only for HTML.
4. Verify a returning-visitor upgrade path: asset URLs changed with the bump, so
   no stale-CSS breakage like the v0.5.0 `.lcat-btn` incident.

## Outcome

Done (repo v0.7.2). theme-toggle shadow deleted -- the repo is back to ZERO module
template shadows; upstream safeJS fix verified in the built JS. Site stylesheet
lcat-theme.css now fingerprinted + SRI'd via head-extra.html, matching the module's
assets, so `find public -name '*.css'` shows only hashed names (needed a clean
`rm -rf public` locally -- hugo does not prune old outputs; CI builds fresh so
deploys were never affected). deploy.sh: css/js moved from the 018 short-TTL
stopgap to `max-age=31536000,immutable`; html/sitemap stay at 300s. Prune note:
`sync --delete` drops prior-hash assets immediately, and old cached HTML (max 300s
stale) references them -- worst case a ~5-minute window where a stale page loses
styling on a demo site; acceptable. Pinned build against published hugo/v0.6.0
passes; CI HUGO_MODULE_VERSION v0.5.0 -> v0.6.0.
