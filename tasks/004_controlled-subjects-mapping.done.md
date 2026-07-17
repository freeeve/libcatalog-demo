# 004 -- Controlled-subject mapping (showcase subjects vs. tags)

## Context

libcat draws a first-class distinction between **controlled subjects** (authority
URIs with localized labels -- e.g. LCSH, Homosaurus) and **uncontrolled tags** (free
genre strings). The demo should exercise that distinction so the subjects facet and the
authority `↗` links on Work pages are populated with real data, not left empty.

## Scope

1. **Genre -> subject mapping.** Hardcover genres arrive as free tags (`tasks/001` puts
   them in `tags[]`). Add a curated mapping from the common ones to controlled subjects
   with authority URIs + labels (`{id, labels:{en: ...}}`), emitting them into
   `subjects[]`. Keep genuinely uncontrolled/quirky tags as `tags[]` -- the point is to
   show both dimensions coexisting.
2. **Authorities.** Prefer LCSH (`id.loc.gov/authorities/subjects/...`) for general
   topics; use Homosaurus (`homosaurus.org/v3/...`) where it fits the collection better.
   Verify each URI resolves. Add `labels.es` (or other) for a subset if the demo goes
   multilingual, to show localized subject labels.
3. **Hierarchy (optional).** Where an authority exposes a broader term, populate
   `broader[]` so the vocabulary-hierarchy behavior (libcat `tasks/015`) is
   demonstrated.
4. **Regenerate facets.** `subjects` in `facets.json` must reflect the mapped subjects
   with correct counts (regenerate, don't hand-edit).

## Acceptance

- Work pages show controlled subjects with resolving authority links, distinct from
  genre tags; the subjects facet lists them with counts.
- At least a handful of subjects demonstrate localized labels and/or `broader` hierarchy.
- Mapping is data-driven (a table), not hardcoded per Work.

## Refs

- libcat `tasks/012` (controlled subjects vs tags vs labels), `tasks/015` (subject
  `broader` hierarchy), `tasks/008` (identifier classification scheme). Module rendering:
  `layouts/page.html` subjects section, `layouts/_partials/facets.html`.
