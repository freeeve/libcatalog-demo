# 006 -- Port the data pipeline from Node to Go (match the ecosystem)

## Context

The data pipeline is currently three Node ESM scripts driven by `npm run data:refresh`
(`scripts/fetch-hardcover.mjs`, `map-subjects.mjs`, `gen-facets.mjs`). The rest of the
libcatalog ecosystem is Go (`lcat project`, the `ingest/` sources, the projector). Porting
the pipeline to Go removes the Node/`npx` dependency from build+deploy and lets it reuse
the framework's own types and projector instead of re-implementing them.

## Scope

1. **Hardcover fetch in Go.** Port `fetch-hardcover.mjs`: GraphQL client, `me` -> user_id,
   paginate `user_books` at `status_id = 3`, map to schema v5 (contributors `Last, First`,
   genres from `cached_tags.Genre`, editions collapsed to one Instance per format, plus
   cover/rating/dateRead/description). Token from `HARDCOVER_API_TOKEN`. Preserve the
   `--introspect` affordance.
2. **Prefer the framework's projector for facets.** `gen-facets.mjs` re-implements what
   `lcat project` already emits (count-desc-then-alpha facets). Where possible, feed the
   fetched data through the graph -> `lcat project` path so `facets.json` comes from the
   real projector, not a bespoke re-implementation. Keep subject mapping
   (`map-subjects.mjs` / `data/subject-map.json`) as a Go step (or fold it into a
   projection input).
3. **Where it should live.** Two options -- decide as part of this task:
   - a small module-local Go command in this repo (e.g. `cmd/data`), or
   - contribute a **Hardcover ingest source upstream** to libcatalog
     (`ingest/hardcover/`, alongside `ingest/overdrive/`) so any adopter can use it, and
     drive it here via `lcat`. The upstream option matches the ecosystem best; per the
     workspace convention, propose it with a task in the libcatalog repo rather than
     editing it from here.
4. **Keep `npm run data:refresh` working** (or replace it with the Go entrypoint) so the
   deploy flow (`tasks/003`, `.github/workflows/deploy.yml`) and docs stay coherent; update
   `scripts/README.md`.

## Acceptance

- `catalog.json` + `facets.json` are produced by Go tooling aligned with `lcat`, with no
  Node/`npx` step in the build.
- Output is byte-compatible with today's pipeline (same schema v5, same facet ordering).
- Token handling unchanged (env var, never committed); documented refresh command.
