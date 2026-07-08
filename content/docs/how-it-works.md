---
title: "How Hugo and libcat fit together"
summary: "The moving parts: Hugo builds the site, libcat turns a catalog into pages, Pagefind adds search."
weight: 10
---

## Hugo, in one paragraph

[Hugo](https://gohugo.io) is a *static site generator*. You write content as
[Markdown](https://commonmark.org/help/) files, Hugo renders them through HTML templates,
and out comes a folder of plain `.html` files. That folder is the whole website — you can
open it locally or upload it anywhere. Nothing runs on the server; there's nothing to
patch, scale, or get hacked.

This site is an ordinary Hugo site. The homepage, the [events](/events/), and these docs
are just Markdown + templates. For example, every event on the events page is one small
Markdown file under `content/events/`:

```markdown
---
title: "Static Sites 101: Build a Website with Markdown"
date: 2026-08-05T18:00:00
location: "Computer Lab"
---
A beginner-friendly workshop on building a static website...
```

## Where libcat comes in

The **catalog** at [/works/](/works/) is the one part that isn't hand-written Markdown.
It's produced by the [libcat](https://github.com/freeeve/libcat) framework and
its Hugo module. The pipeline is deliberately boring — each stage is a file you can open:

1. **Bibliographic data** (BIBFRAME/MARC records, or in this demo a reading list from
   [Hardcover](https://hardcover.app)) is the source of truth.
2. **The projector** (`lcat project`) flattens that into two static JSON files:
   `catalog.json` (one entry per work) and `facets.json` (precomputed facet counts).
3. **The libcat Hugo module** reads those JSON files and *mints one page per work* —
   via a Hugo "content adapter", with no per-book Markdown — plus the facet navigation and
   work detail pages. This site simply imports the module:

   ```toml
   # hugo.toml
   [module]
     [[module.imports]]
       path = "github.com/freeeve/libcat/hugo"
   ```

4. **Pagefind** indexes the built HTML afterward, giving real full-text search that runs
   entirely in the browser — no search server.

So the adopter site (this repo) provides *config, data, a few content pages, and light
branding*; the module provides the catalog machinery. That separation is the whole idea:
you get a catalog without running catalog software.

## Controlled subjects vs. tags

libcat also models the difference between **controlled subjects** — authority URIs
with localized labels, like [LCSH](https://id.loc.gov/authorities/subjects.html) and
[Homosaurus](https://homosaurus.org) — and free **tags** (genre strings). Both are faceted
side by side; on a work page the subjects carry a resolving `↗` link to the authority
record. See any [work in the catalog](/works/) for both dimensions at once.

Next: [build and deploy it yourself](/docs/build-and-deploy/).
