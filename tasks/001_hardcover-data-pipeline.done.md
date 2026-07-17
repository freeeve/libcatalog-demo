# 001 -- Hardcover data pipeline (read shelf -> catalog.json)

## Status (done)

Pipeline built, run, and committed: `assets/catalog.json` is Eve's real Hardcover
*Read* shelf (**102 works**, 101 covers, 97 ratings, 98 read-dates), `facets.json`
regenerated and consistent, and the site builds/paginates over the full set.

- `scripts/fetch-hardcover.mjs` -- reads the authenticated Read shelf via Hardcover
  GraphQL (schema confirmed by introspection: `me` -> user_id, `user_books.status_id=3`,
  `last_read_date`, `cached_tags.Genre`, editions collapsed to one Instance per format).
  Maps to schema v5 + `cover`/`rating`/`dateRead`/`description`. Token from
  `HARDCOVER_API_TOKEN` (falls back to `HARDCOVER_TOKEN`); prepends `Bearer`; never
  committed.
- `scripts/gen-facets.mjs` / `map-subjects.mjs` -- regenerate + promote subjects;
  idempotent. `npm run data:refresh` runs the whole chain.
- The module content adapter forwards only a fixed field set, so cover/rating/dateRead
  are surfaced via a documented adapter shadow (`content/works/_content.gotmpl`); upstream
  passthrough requested in `../libcat/tasks/022` so the shadow can be dropped.

Not exercised: the `lcat project` MARC/BIBFRAME path (§3, preferred) -- the direct
Hardcover->catalog map is the documented fallback and emits the same schema-v5 shape, so
the two converge. Re-run `npm run data:refresh` when Eve reads more.

## Context

The demo currently ships placeholder public-domain classics in `assets/catalog.json`.
The real content is the books Eve has read, tracked on Hardcover. This task builds the
pipeline that turns Eve's Hardcover "read" shelf into the projected `catalog.json` +
`facets.json` the libcat module consumes (schema **version 5**).

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
- libcat projector contract (`tasks/009`), schema version 5 (module README "Schema
  version"); controlled subjects vs tags (libcat `tasks/012`).
