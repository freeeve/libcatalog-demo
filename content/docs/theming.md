---
title: "Theming it, with examples"
summary: "The module ships an accessible light/dark theme out of the box; re-brand by setting a few CSS variables, add your own chrome, and shadow templates only as a last resort."
weight: 30
---

The libcat module ships a complete, accessible default theme -- including **light and
dark modes with a toggle in the header** -- driven by CSS custom properties. An adopter
themes by **layering on top**, no forking, in escalating order of effort:

## 1. Do nothing

This site's catalog -- the works list, detail pages, facets -- renders in the module's
default theme, untouched. The default is WCAG-AA in both light and dark, and both modes
come for free. That's the baseline every adopter starts from.

## 2. Recolor with tokens

To re-brand, set the module's `--lcat-*` variables in your own stylesheet and every
component re-themes at once -- module and custom chrome alike:

```css
:root {
  --lcat-accent: #115c52;  /* your brand color (keep WCAG-AA on the bg) */
  --lcat-bg: #fbf9f4;      /* warm paper */
  --lcat-fg: #1c1b18;      /* ink */
}
```

Load your stylesheet after the module's `lcat.css` and the variables win on cascade.
If you re-set tokens, check contrast in **both** modes (or scope dark overrides under
`[data-lcat-theme=dark]`).

## 3. Add components

For things the module doesn't ship, add your own classes. The homepage hero, event
cards, and cover thumbnails here are all plain `evl-*` classes in this site's
`assets/lcat-theme.css`. The trick that keeps them coherent: they **alias the module's
tokens** instead of pinning colors --

```css
:root {
  --evl-surface: var(--lcat-surface);
  --evl-gold: var(--lcat-accent);
}
```

so the custom chrome flips with the light/dark toggle too, automatically.

## 4. Use the injection hooks

The module's base template exposes empty-by-default hooks an adopter fills by creating
a file of the same name -- and they cover the whole chrome:

- `_partials/head-extra.html` -- extra `<head>` markup (this site adds its stylesheet
  and favicons here; SEO/OpenGraph/JSON-LD come from the module by default),
- `_partials/banner.html` -- a site-wide ribbon above the header (here: the "this is
  a demo" notice; a real library might post closure notices),
- `_partials/brand.html` -- the header brand slot (here: a book colophon + wordmark),
- `_partials/footer.html` -- the site footer,
- a `hero` block for full-width sections (the homepage welcome panel).

The primary nav needs no hook at all: define `[[menu.main]]` entries in `hugo.toml`
and the module renders an accessible nav from them.

## 5. Shadow a template (only when you must)

Any file in the module's `layouts/` can be replaced by putting a file at the same path
in your site. The cost: after a module upgrade you must re-diff your copy against the
module's. This site used to shadow `baseof.html` for its header chrome; since the
module grew the hooks above it shadows **nothing** -- every customization on this
site is tokens, added CSS, hooks, or its own sections. That's the target to aim for.

## 6. Add whole pages and sections

The homepage, [events](/events/), and these docs aren't part of the module at all --
they are ordinary Hugo content + layouts in this repo. Mixing your own sections with
the catalog is exactly the point.

Next: [what it costs to run, and who can edit it](/docs/running-it/).
