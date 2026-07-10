# 029 -- bump-libcat-v0.141.2

Opened 2026-07-10.

Currency bump to the latest published hugo tag: v0.100.1 -> v0.141.2.

## Outcome

- `HUGO_MODULE_VERSION` repo variable set to v0.141.2; CI pins hugo@v0.141.2.
- Schema bumped v11 -> v12. Not a no-op like 028: the projector now emits a
  new sidecar `similar.json` (its own schema v1) holding each work's
  neighbour rail (shared subjects/tags/contributors, pool limit 8).
- Wired the new file into the adopter:
  - `refresh-data.sh` now copies `similar.json` into `assets/` alongside
    catalog.json + facets.json (it was silently dropped otherwise -- the
    module renders no rail when similar.json is absent, so the build stays
    green but the feature is invisible).
  - committed `assets/similar.json`; bumped schema-version mentions to v12
    in CLAUDE.md + scripts/README.md.
- Reprojected build/catalog.nq with lcat v0.141.2 (installed from the
  published tag -- sibling working tree had concurrent uncommitted work).
- Verified locally: similar rail renders on 100/102 works (2 have no
  neighbours, by design), neighbour links resolve to real work pages. The
  progressive-enhancement lcat-similar.js loads only when neighbours > shown
  (both 8 here), so it is correctly absent and all tiles render server-side.
- lcatd sandbox note from tasks/027 unchanged; applies only on sandbox redeploy.
