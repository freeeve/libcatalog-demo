# Data pipeline

How the projected data under `assets/` (`catalog.json` + `facets.json`, schema
version 5) is produced. All commands run from the repo root.

```
Hardcover "read" shelf
        │  scripts/fetch-hardcover.mjs   (npm run data:fetch)
        ▼
assets/catalog.json      works with tags[] (genres), instances[], cover/rating/dateRead
        │  scripts/map-subjects.mjs      (npm run data:subjects)
        ▼
assets/catalog.json      + controlled subjects[] promoted from tags via data/subject-map.json
        │  scripts/gen-facets.mjs        (npm run data:facets)
        ▼
assets/facets.json       count-desc-then-alpha facet counts for every dimension
```

One-shot refresh (fetch + subjects + facets):

```
export HARDCOVER_TOKEN='...'      # Hardcover -> account settings -> API. Never commit it.
npm run data:refresh
```

Or run the stages individually: `npm run data:fetch`, then `npm run data:build`
(= `data:subjects` + `data:facets`). `data:build` is idempotent -- safe to re-run.

## Stages

- **`fetch-hardcover.mjs`** -- reads the authenticated user's *Read* shelf from the
  Hardcover GraphQL API (`status_id = 3`), paginating fully, and maps each book to a
  Work: title/subtitle, contributors (normalized to `Last, First`), genre `tags[]`,
  `formats[]`/`instances[]` from editions (ISBN-13/10), plus `cover`, `rating`, and
  `dateRead` for display. Controlled `subjects[]` are left to the next stage.
  - The token is read from `HARDCOVER_TOKEN` and never written to disk.
  - Hardcover's schema evolves; confirm field shape with
    `HARDCOVER_TOKEN=... node scripts/fetch-hardcover.mjs --introspect user_books`
    and adjust the query if a field has moved. The mapper uses optional chaining, so a
    missing field is omitted rather than fatal.
- **`map-subjects.mjs`** -- promotes mappable genre tags into controlled `subjects[]`
  (LCSH / Homosaurus authority URIs with localized labels + `broader`) from the
  data-driven table in `data/subject-map.json`, leaving unmapped tags in `tags[]`.
  See `tasks/004`.
- **`gen-facets.mjs`** -- regenerates `facets.json` from `catalog.json`. Never
  hand-edit facet counts; run this instead.

## Real-pipeline path (preferred, tasks/001 §3)

Where an ISBN resolves to a real MARC/BIBFRAME record, that record should be run
through `lcat project` (the libcatalog projector) instead of the direct Hardcover
mapping, so the demo exercises the genuine BIBFRAME -> project path. `fetch-hardcover`
emits the same schema-v5 shape `lcat project` produces, so the two paths converge on
`catalog.json`; the direct map is the documented fallback for records with no
retrievable bib record. Document which path each record took when this lands.

## Refresh cadence

Re-run `npm run data:refresh` whenever Eve reads more books. In CI this can run on a
schedule before the build/deploy (see `tasks/003`); the token is supplied as a secret,
never committed.
