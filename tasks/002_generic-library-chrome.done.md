# 002 -- Generic-library chrome & "Eve's Library" branding

## Context

Out of the box the module renders a functional but bare catalog (header with brand +
search, facet sidebar, Work list/detail). To read as a real public-library website and to
be transparent that it is a demo, the site needs light branding and a couple of content
pages -- layered on top of the module without forking its templates.

## Scope

1. **Identity.** Shadow `assets/lcat.css` (or add a small override stylesheet) for an
   "Eve's Library" look: color accent, header/logo treatment, typography. Keep the
   module's accessibility intact (focus styles, contrast >= WCAG AA -- verify in a real
   browser; jsdom can't check contrast).
2. **Homepage.** The module's `list.html` shows the Work list on `/`. Add a hero / intro
   strip above it (a "Welcome to Eve's Library" blurb and, if data allows, a "Recently
   read" or "Highly rated" shelf using the covers/ratings from `tasks/001`). Do this by
   shadowing `layouts/list.html` (or a `home.html`) so the module list still renders
   below.
3. **About / demo disclosure.** Add an `/about/` page stating plainly this is a demo of
   the **libcatalog framework + Hugo**, with links to both repos and a short "how it's
   built" note (BIBFRAME -> projector -> Hugo module -> Pagefind). Needs a simple page
   layout for non-Work content (the module's `page.html` expects Work params), e.g. a
   `layouts/page.html` guard or a dedicated section layout.
4. **Persistent demo note.** A footer on every page: "Built with libcatalog + Hugo -- a
   demo, not a real collection." Add it via a `baseof.html` override or a footer partial.
5. **Cover art (optional).** If `tasks/001` captured cover URLs, surface them on the Work
   card and detail (extend the card partial). Respect Hardcover/source image terms; fall
   back gracefully when a cover is missing.

## Acceptance

- The site looks like a branded public-library catalog titled "Eve's Library".
- Every page carries a clear, honest "this is a libcatalog + Hugo demo" note, and an
  About page explains it.
- Overrides sit on top of the module (no vendored copy of module templates); the module
  can still be version-bumped without merge pain.
- a11y unaffected (re-run the module's axe audit against this site's `public/`).

## Refs

- libcatalog module override model (hugo/README "Overriding"), `layouts/baseof.html`,
  `layouts/list.html`, `layouts/page.html`, `layouts/_partials/work-card.html`,
  `assets/lcat.css`. Accessibility posture: libcatalog `tasks/014`.
