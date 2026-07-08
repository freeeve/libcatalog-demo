---
title: "About this demo"
layout: about
description: "Eve's Library is a public demo of the libcat framework and its Hugo module — BIBFRAME to projector to a faceted, accessible, statically searchable catalog."
---

**Eve's Library is a demo, not a real library collection.** It exists to show what an
adopter gets from the [libcat](https://github.com/freeeve/libcat) framework and
its [Hugo module](https://github.com/freeeve/libcat/tree/main/hugo): a faceted,
accessible, multilingual-capable discovery site with static full-text search — and no
backend to run.

## How it's built

The pipeline is deliberately boring, which is the point — every stage is a plain build
artifact you can inspect:

1. **BIBFRAME / bibliographic records** are the source of truth (the framework models
   Works, Instances, contributors, controlled subjects, and identifiers as a graph).
2. **The projector** (`lcat project`) flattens that graph into two static JSON files —
   `catalog.json` (one entry per Work) and `facets.json` (precomputed facet counts).
3. **The Hugo module** mints one page per Work from `catalog.json` via a content
   adapter — no per-record markdown — plus the facet navigation, Work detail pages, and
   accessible chrome. This site imports the module the way any adopter would and only
   supplies config, data, and light branding on top.
4. **Pagefind** indexes the built HTML after Hugo runs, giving real ranked, per-language,
   CJK-capable full-text search that ships as static files.

## What's on display

- **Works and Instances.** Each Work clusters its editions (ebook / audiobook /
  physical); a Work with multiple formats appears under each.
- **Controlled subjects vs. tags.** Subjects are authority-controlled (LCSH, Homosaurus)
  with resolving `↗` links and localizable labels; genre tags are free strings. Both
  dimensions are faceted, side by side.
- **Faceted browsing** by subject, contributor, format, language, and classification,
  with counts straight from `facets.json`.
- **Accessibility.** The module targets WCAG 2.1 AA — skip link, focus styles, heading
  order, and keyboard-navigable search.

## Try the cataloging backend

The discovery site above is static — no backend to run. But the records themselves are
produced by libcat's cataloging backend (`lcatd`): a record editor, a review queue,
copy cataloging, and editing profiles. A live **sandbox** instance lets you explore that
side too, backed by the same 102 works:

**[try.libcat.evefreeman.com ↗](https://try.libcat.evefreeman.com/)** — sign in
as `demo@example.org` / `readonlydemo`.

It's a sandbox: **edit a record and watch your change render**, search all of LCSH in the
subject picker (live from `id.loc.gov`) and all of [Homosaurus](https://homosaurus.org)
(the full vocabulary ships with the demo), and see existing subjects with their real
headings — then refresh, and it's all back. **Nothing is ever saved.** It runs as a single
scale-to-zero AWS Lambda behind CloudFront, so the first request after it has been idle may
take a moment.

## The data

The catalog is Eve's real reading history, sourced from
[Hardcover](https://hardcover.app) — the books on her *Read* shelf — through a
reproducible fetch-and-project pipeline (`npm run data:refresh`). Genre tags come across
as free text; the build then promotes the mappable ones into controlled subjects (LCSH
and Homosaurus) while leaving quirkier tags as-is, so both dimensions appear side by
side. Covers, ratings, and read dates come from Hardcover too.

## Source

- Framework + Hugo module: <https://github.com/freeeve/libcat>
- This adopter site: a plain Hugo site that imports the module.
