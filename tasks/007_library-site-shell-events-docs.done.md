# 007 -- Library site shell: real homepage, events, and build/theming docs

## Context

Demonstrate that libcat is *one section* of an ordinary Hugo-built library website,
not the whole site. Make `/` a normal public-library homepage (not the catalog), add
Hugo-backed demo events, and add documentation pages that explain how it's built, how to
run/edit it cheaply, and how to theme it. Everything clearly labeled demo content.

## Scope

1. **Homepage = library landing** (not the catalog). Hero/welcome, hours + visit info,
   upcoming events, a "from the catalog" teaser linking to `/works/`, news, and a
   "built with libcat + Hugo" explainer. Catalog stays at `/works/`.
2. **Primary nav** (Hugo menus): Home, Catalog, Events, About, Guide.
3. **Events** (native, Hugo content under `content/events/`): list + single layouts,
   date badges, upcoming/past split, homepage widget. (The linked hugo-calendar-widget is
   a blog-archive calendar, not an events calendar -- referenced in docs, not used.)
4. **Docs / "How this is built"** (`content/docs/`): how Hugo works + how libcat ties
   in; step-by-step build & deploy commands; theming guide with examples; a
   running-costs + minimal-skills page (markdown/git, static hosting is ~pennies) that
   introduces Sveltia CMS as the low-skill editing path.
5. **Sveltia CMS** scaffold at `/admin/` (git-backed editing UI) + config, clearly marked
   as needing an OAuth backend to write.
6. Clearly-demo framing throughout; keep a11y clean and redeploy.

## Acceptance

- `/` reads as a real library homepage; catalog reachable at `/works/`.
- `/events/` + event pages render from Hugo content; homepage shows upcoming events.
- Docs cover architecture, step-by-step build/deploy, theming, and cost/skills + Sveltia.
- axe clean; site builds and deploys; nav works.
