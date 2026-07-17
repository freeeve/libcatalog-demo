# 020 -- Bundle the full Homosaurus vocabulary in the cataloging sandbox

The catalog carries Homosaurus subject URIs (tasks/004) but the sandbox only
loaded scheme `lcsh`, so those subjects rendered unresolved and the picker had no
Homosaurus at all.

Approach: Homosaurus is small (~3.9k terms), so unlike LCSH (corpus subset) we
bundle the WHOLE vocabulary -- every term searchable locally via `/v1/terms`,
no live proxy needed. `lcat vocab-subset` couldn't do this (it fetches per-term
`<uri>.skos.nt`, an id.loc.gov convention; generalizing = libcat tasks/124),
so `deploy/lcatd/gen-homosaurus.sh` converts the official n-triples dump
(https://homosaurus.org/v3.nt, 7.4MB) to a 3.5MB `homosaurus.nq`: SKOS surface
predicates only, quads tagged `<authority:homosaurus>`.

## Changes

- `deploy/lcatd/gen-homosaurus.sh` (new) + committed `homosaurus.nq`
  (3,885 prefLabels / 23,668 quads; https-keyed, matching catalog URIs natively).
- `build.sh` stages it at `grains/data/authorities/vocab/homosaurus.nq`.
- `main.tf`: `LCATD_VOCAB_SCHEMES = "lcsh,homosaurus"`.
- About page + cataloging-sandbox guide mention Homosaurus.

## Verify

Local lcatd against the staged grains: `vocabularies loaded [homosaurus lcsh]`;
`/v1/terms/resolve?id=...homoit0000827` -> "LGBTQ+ books" (with narrower links);
`/v1/terms?scheme=homosaurus&q=drag` -> 15 local hits. GOTCHA hit during testing:
killing a `go run` wrapper orphans the lcatd child and the port stays bound --
stale-server answers look like real regressions; kill by `lsof -tiTCP:<port>`.
Then: rebuild zip, terraform apply (env + zip), verify live, CI static deploy for
the copy changes.

## Outcome

Done (repo v0.8.0). Deployed: in-place Lambda update (new zip + env). Verified live:
`/config` schemes `["homosaurus","lcsh","folk"]`; resolve homoit0000827 ->
"LGBTQ+ books"; `/v1/terms?scheme=homosaurus&q=pride` -> 7 local hits (full-vocab
search); writes still 403. Upstream ask filed: libcat tasks/124 (vocab-subset
--fetch-suffix / --dump modes). Static site copy (About + sandbox guide) deployed
via CI.
