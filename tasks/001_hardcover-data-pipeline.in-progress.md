# 001 -- Hardcover data pipeline (read shelf -> catalog.json)

## Status (blocked on token)

Pipeline **built and reproducible**; the real fetch is **blocked on a Hardcover API
token**, which is not available in this environment (unauthenticated introspection
returns "Unable to verify token"). Done:

- `scripts/fetch-hardcover.mjs` -- read-shelf fetch + map to schema v5 (title,
  subtitle, contributors as `Last, First`, genre tags, editions -> instances/formats,
  cover/rating/dateRead). Token from `HARDCOVER_TOKEN`, never committed. `--introspect`
  mode to confirm the live schema.
- `scripts/gen-facets.mjs` -- regenerate `facets.json` (count-desc-then-alpha), runnable
  now; verified idempotent.
- `npm run data:refresh` (fetch -> subjects -> facets); documented in `scripts/README.md`
  and the root README.

To finish: `export HARDCOVER_TOKEN=...` then `npm run data:refresh`; confirm field
shapes with `--introspect` first (Hardcover's schema drifts), then commit the real
`catalog.json`/`facets.json`. The `lcat project` MARC/BIBFRAME path (§3, preferred) is
documented as the convergent alternative but likewise needs live records to exercise.
The catalog currently ships placeholder classics.

## Context

The demo currently ships placeholder public-domain classics in `assets/catalog.json`.
The real content is the books Eve has read, tracked on Hardcover. This task builds the
pipeline that turns Eve's Hardcover "read" shelf into the projected `catalog.json` +
`facets.json` the libcatalog module consumes (schema **version 5**).

## Inputs

- A Hardcover API token (account settings -> API) and Eve's user identifier.
- Endpoint: `https://api.hardcover.app/v1/graphql`, `Authorization: Bearer <token>`.
- Confirm the current GraphQL schema shape before coding -- Hardcover's `user_books` /
  `books` / `editions` fields evolve. Introspect or check https://docs.hardcover.app.

## Scope

1. **Fetcher.** A small script (`scripts/fetch-hardcover.mjs` or a Go tool) that queries
   the authenticated user's read books (`user_books` where the "read" status), paginating
   fully. For each: title, subtitle, contributions (author/narrator/etc. + role),
   editions (ISBN-13/10, format: ebook/audiobook/physical), cover image URL, description,
   genres/tags, user rating, date read. Keep the token out of the repo (env var).
2. **Map to catalog schema (version 5).** Emit `catalog.json` works with `id`, `title`,
   `subtitle`, `contributors[]` (`{name, role}`; normalize author names to `Last, First`),
   `tags[]` (from Hardcover genres), `languages[]` (default `eng` unless known), `formats[]`
   (from editions), `instances[]` (`{id, format, isbns[]}`). Leave controlled `subjects[]`
   to `tasks/004`. Stable `id`s (slug of Hardcover book id) so URLs don't churn.
3. **Preferred: exercise the real pipeline.** Where an ISBN resolves to a real bib
   record, pull MARC/BIBFRAME (libcodex / LoC / OpenLibrary) and run it through
   `lcat project` so the demo shows the genuine BIBFRAME -> project path, not a bespoke
   JSON shim. Fall back to the direct Hardcover -> catalog mapping for records with no
   retrievable MARC. Document which path each record took.
4. **facets.json.** Regenerate from the projector (or a `scripts/gen-facets.mjs` that
   mirrors count-desc-then-alpha ordering) so counts stay correct at real scale. Never
   hand-maintain counts once this lands.
5. **Refresh.** Make the fetch reproducible (one command) and note how to re-run it when
   Eve reads more; wire it into the deploy flow (`tasks/003`) or run it manually.

## Acceptance

- `assets/catalog.json` reflects Eve's real Hardcover read shelf; `facets.json` is
  generated and consistent; the site builds and paginates over the full set.
- Covers/ratings/dates captured for later display use (`tasks/002`).
- The token is never committed; the fetch is documented and repeatable.

## Refs

- Hardcover API: https://api.hardcover.app/v1/graphql , https://docs.hardcover.app
- libcatalog projector contract (`tasks/009`), schema version 5 (module README "Schema
  version"); controlled subjects vs tags (libcatalog `tasks/012`).
