# 024 -- bump to hugo/v0.9.0 (scheme-aware subjects, schema v8)

Filed from libcat (tasks/141, 2026-07-06). Leave uncommitted for the
demo session to pick up.

libcat tagged `hugo/v0.9.0` + `v0.15.0`: the projector now emits schema
**v8** (subjects carry a `scheme` vocabulary code) and the module targets it
-- a v7 catalog.json fails the version check, so the module bump and the
reproject (with a v0.15.0 `lcat project`) must land together.

What changes:

- Subject term pages key by scheme-prefixed slug (`homosaurus-lesbians`);
  for this demo's single-vocabulary corpus the scheme is derived from the
  homosaurus namespace, so EXISTING SUBJECT TERM URLS CHANGE (gain the
  `homosaurus-` prefix). Check inbound links/redirects if any were shared.
- Sidebar renders one facet group per vocabulary; single-scheme corpora
  still get the one "Subjects" group. Optional `[[params.subjectSchemes]]`
  (scheme/name) names it; `[params] facetLimit` caps rendered entries;
  groups over 10 entries gain a type-to-filter box.
- Term pages now title with the human label plus vocabulary.

Recipe: bump `HUGO_MODULE_VERSION` to v0.9.0, rebuild `lcat` from
libcat v0.15.0, reproject, deploy.

## Done (2026-07-06)

Landed on **hugo/v0.21.0** (lockstep `v0.21.0`), not v0.9.0 -- libcat
tagged through v0.21.0 the same day, the working-tree `replace` builds
against that state, and the module now targets schema **v9** (v8's subject
schemes plus `{value, label}` classifications and language display names,
module tasks/142).

- Reprojected offline from the existing `build/catalog.nq` (`lcat project`,
  no Hardcover token needed): 102 works, schema v9.
- The corpus turned out **two-scheme**, not single: the projector derives
  `lcsh` from the id.loc.gov namespace alongside `homosaurus`. All 13
  subject term URLs changed (`lcsh-*` / `homosaurus-*` prefixes). No site
  content linked the old URLs; no redirects existed to preserve.
- `hugo.toml`: added `[[params.subjectSchemes]]` naming the two groups
  (LCSH, Homosaurus). Sidebar renders both plus type-to-filter boxes on
  groups over 10 entries; term h1s read "Subject: LGBTQ books (Homosaurus)";
  the language facet shows "English" via the module's LOC table.
- `HUGO_MODULE_VERSION` repo variable bumped v0.8.0 -> v0.21.0
  (`hugo/v0.21.0` is pushed; the Go proxy resolves it).
- Module bug found while verifying, filed as libcat tasks/149 (left
  uncommitted there per policy): term page head `<title>`/`og:title` use the
  humanized slug ("Homosaurus-Lgbtq-Books") instead of the resolved display
  label the h1 gets.
- Skipped: `facetLimit` (defaults fine) and the v0.21.0 opt-in negative
  facet filters (`[params.facets] negatives = true`) -- no task asked for
  them; enable deliberately if the demo should showcase exclusions.
