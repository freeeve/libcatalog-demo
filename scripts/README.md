# Data pipeline

How the projected data under `assets/` (`catalog.json` + `facets.json`, schema
version 9) is produced. All commands run from the repo root.

```
Hardcover "read" shelf
        │  lcat hardcover      (ingest: Read shelf -> BIBFRAME grains + catalog.nq)
        ▼
build/catalog.nq         one Work per book, one Instance per format; cover/rating/
        │                dateRead/description carried on the feed graph as `extra`
        │  lcat project       (project the graph at the module's current schema)
        ▼
assets/catalog.json      works with controlled subjects[], instances[], extra{...}
assets/facets.json       count-desc-then-alpha facet counts for every dimension
```

Both steps are the real **libcat** pipeline (`../libcat/cmd/lcat`), not a
hand-rolled transform. The schema version, controlled-subject mapping, facet
counts, and the `held` holdings signal are all owned by the projector -- the next
schema bump is a re-run of this pipeline, not a hand-edit. This replaces the old
Node scripts (`fetch-hardcover.mjs`, `map-subjects.mjs`, `gen-facets.mjs`), retired
in tasks/008 once libcat shipped a first-party Hardcover ingest source
(framework tasks/026).

One-shot refresh (ingest + project):

```
export HARDCOVER_API_TOKEN='...'      # Hardcover -> account settings -> API. Never commit it.
npm run data:refresh                  # = bash scripts/refresh-data.sh
```

Requires a sibling `../libcat` checkout (Go 1.25+) -- the same checkout the Hugo
module `replace` in `go.mod` resolves against. `refresh-data.sh` runs `lcat hardcover`
into `build/` (gitignored intermediate grains), then `lcat project` into `assets/`.

## Stages

- **`lcat hardcover --out build/`** -- reads the authenticated user's *Read* shelf from
  the Hardcover GraphQL API (`status_id = 3`), paginating fully, clusters a book's
  editions into one Work with one Instance per format, maps genre tags to controlled
  subjects (LCSH / Homosaurus, from `../libcat/ingest/hardcover/subject-map.json`),
  and writes BIBFRAME grains + `catalog.nq` under `build/`. The token is read from
  `HARDCOVER_API_TOKEN` and never written to disk. Adopter display fields
  (`cover`, `rating`, `dateRead`, `description`) ride the feed graph into each Work's
  reserved `extra` object, which the module content adapter forwards verbatim into page
  params -- so `covers = true` renders them.
- **`lcat project --catalog build/catalog.nq --provider hardcover --out build/projected`**
  -- projects the graph to `catalog.json` + `facets.json` (+ an unused `redirects.json`)
  at the module's current schema version. `refresh-data.sh` copies the two files the
  module reads into `assets/`. Never hand-edit facet counts or the schema version --
  re-run the projector.

### Offline replay

`lcat hardcover --source <shelf.json>` replays a captured `user_books` JSON array with
no token and no network; forward it through the npm script:
`npm run data:refresh -- --source path/to/shelf.json`. To reproject an existing
`build/catalog.nq` without re-fetching, run `lcat project` directly (see the header of
`refresh-data.sh`).

## The holdings signal (`held`)

Schema v6 added `held` on each Work / Instance (physical items, or a live-availability
feed that still lists the Work). This is a read-shelf demo with neither, so the projector
honestly emits `held: false` for every Work (omitted from the JSON). The module renders
unheld works unchanged -- there is no holdings badge -- so no visual indicator appears,
by design. Availability stays off here (no `[params.availability]`).

## Refresh cadence

Re-run `npm run data:refresh` whenever Eve reads more books. In CI this can run on a
schedule before the build/deploy (see `tasks/003`); the token is supplied as a secret,
never committed.
