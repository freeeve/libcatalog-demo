# 023 -- Bump to hugo/v0.8.0: linked cards, fixed term URLs, search modal, ?q

Upstream shipped our whole filed batch (their 127/128/129/131 -> hugo/v0.8.0):

- work cards link subject chips (labeled controlled-subject terms now, not raw
  tag strings) and contributor names to their term pages;
- term links resolve from Hugo's minted pages, fixing the dotted-name 404s
  (kuang-r.f., brite-poppy-z.);
- Pagefind Component UI moved into a modal dialog (no more header blowup /
  overlapping drawer);
- the SearchAction ?q= deep link is honored.

Schema stays v7 -- no data refresh, no demo file changes; this bump is CI-pin-only.

## Status

Verified against the sibling head (build + axe 504 pages clean + CDP-driven
modal screenshots light/dark; kuang link -> minted page exists). BLOCKED on
upstream pushing the `hugo/v0.8.0` tag (asked via ../libcatalog/tasks/132).
Once pushed: verify `scripts/pin-module.sh v0.8.0` builds, set CI
`HUGO_MODULE_VERSION=v0.8.0`, commit this task done (triggers deploy), verify
live.

## Outcome

Done (repo v0.10.0). Upstream pushed hugo/v0.8.0 (their tasks/132 ask honored
within the hour); published-pin build verified via scripts/pin-module.sh; CI
HUGO_MODULE_VERSION v0.7.0 -> v0.8.0. Live-verified after deploy: card chips +
authors are links, /contributors/kuang-r.f./ resolves (old kuang-r-f 404 gone
from all links), search opens the modal, /works/?q= runs the query. Zero
demo-side code changes -- the whole feature batch arrived by pin bump, exactly
the file-upstream-and-wait policy working as intended.
