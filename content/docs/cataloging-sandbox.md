---
title: "Try the cataloging sandbox"
summary: "A hands-on tour of lcatd, libcat's cataloging backend: edit a record, search all of LCSH, watch your change render — and refresh to undo everything."
weight: 50
---

The static site you're reading needs no server -- but the *records* behind it were made
somewhere. That somewhere is **lcatd**, libcat's cataloging backend: the tool a
cataloger would actually use. A public sandbox instance runs at:

**[try.libcat.evefreeman.com ↗](https://try.libcat.evefreeman.com/)**
-- sign in as `demo@example.org` / `readonlydemo`.

It's loaded with the same 102 works you see in [the catalog](/works/). It runs in
**sandbox mode**: the editor lets you change things and shows your edits as if they were
saved, but nothing ever persists -- the server refuses all writes, and a page refresh
puts everything back. Break nothing by trying everything.

## Things to try

- **Edit a record.** Open any work and change its title or add a contributor, then
  *Save*. Your change renders immediately -- that's the server's dry-run of the exact
  edit a real cataloger would commit. Refresh, and it's gone.
- **Search all of LCSH.** In the subject picker, type a topic. Suggestions come live
  from the Library of Congress (`id.loc.gov`) -- the sandbox proxies the real authority
  service, so you're searching the actual Library of Congress Subject Headings, all of
  them. The subjects already on records resolve to their real headings the same way.
- **Browse all of Homosaurus.** The sandbox also carries the complete
  [Homosaurus](https://homosaurus.org) -- the international LGBTQ+ linked-data
  vocabulary, nearly 4,000 terms -- bundled whole and searched locally. It shows two
  vocabularies working side by side: one too big to ship (LCSH, searched live), one
  small enough to carry entirely.
- **Preview the MARC.** The editor has a dual view: the friendly form and the
  underlying MARC fields. Previewing shows how your edit lands in the record.
- **Validate.** Run validation on a record and see what a cataloging workflow would
  flag before publishing.

## What it demonstrates

libcat is two tiers. Tier 1 is the static discovery site (this one): cheap, fast,
nothing to run. Tier 2 is lcatd, for the back room: record editing with dry-run
preview, review queues, copy cataloging, batch operations, controlled-vocabulary
management, and MARC round-tripping. Publish from Tier 2 and Tier 1 rebuilds -- the
grains lcatd edits are exactly what `lcat project` projects into this site's data.

## What it costs to run (almost nothing, again)

The sandbox is a single small AWS Lambda behind a CDN -- it scales to zero between
visitors, keeps the whole demo catalog in memory, and needs no database. Idle cost is
effectively $0; that's why a public demo like this can just stay up. (It also means the
first request after a quiet spell takes a moment to wake up.) Adopters who want the
same thing get it as a ready-made Terraform module in the
[libcat repo](https://github.com/freeeve/libcat).

Back to [all guides](/docs/), or [see how the static site is built](/docs/how-it-works/).
