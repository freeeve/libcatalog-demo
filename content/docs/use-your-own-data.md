---
title: "Use your own data"
summary: "Point the same pipeline at your own Hardcover shelf, MARC export, or OverDrive scan, and the catalog becomes yours."
weight: 25
---

Everything about this site except the data is generic. The catalog you're browsing is
Eve's Hardcover *Read* shelf, but the pipeline that produced it -- libcat's `lcat`
tool -- takes other sources too. Swap the source, re-run two commands, and the same
site design serves your collection.

## The two-step shape

Whatever the source, the pipeline is always **ingest, then project**:

1. **Ingest** turns your source records into BIBFRAME "grains" -- one small graph file
   per Work, the framework's source of truth.
2. **Project** (`lcat project`) flattens those into the two static JSON files the Hugo
   module reads: `catalog.json` and `facets.json`.

The projected files are derived artifacts. You never edit them; you re-run the
projector.

## Source: a Hardcover shelf (what this demo uses)

If you track reading on [Hardcover](https://hardcover.app), this repo works as-is with
*your* account -- the token decides whose shelf it fetches:

```bash
export HARDCOVER_API_TOKEN='...'   # your token: Hardcover -> account settings -> API
npm run data:refresh
```

`lcat hardcover` reads your *Read* shelf, clusters each book's editions into one Work
with one Instance per format (ebook / audiobook / physical), maps mappable genre tags
to controlled subjects (LCSH, Homosaurus), and carries covers, ratings, and read dates
along. There's also an offline mode that replays a captured shelf JSON with no token
and no network: `npm run data:refresh -- --source shelf.json`.

## Source: MARC records

Libraries with a real ILS export MARC. libcat ingests it directly:

```bash
lcat ingest --provider marc --source records.mrc --out build/
lcat project --catalog build/catalog.nq --out build/projected
```

## Source: an OverDrive collection

A cached OverDrive/Thunder scan of a digital collection ingests the same way
(`--provider overdrive`), and pairs with the module's optional live-availability
adapters if you want real-time "available now" from OverDrive or a DAIA-speaking ILS.

## After that, it's the same site

Copy `catalog.json` + `facets.json` into `assets/`, run the [build](/docs/build-and-deploy/),
and every page -- work detail, facets, search -- regenerates from your data. Nothing in
the templates is specific to books-Eve-read; it's all driven by what the projector
emits.

Next: [theme it](/docs/theming/) to make it look like yours, too.
