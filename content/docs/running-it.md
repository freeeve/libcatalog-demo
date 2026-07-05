---
title: "What it costs, and who can run it"
summary: "Static hosting is pennies a month, and editing needs only Markdown and a few Git commands — or a friendly CMS."
weight: 40
---

## It's cheap because nothing runs

A static site is just files. There's no database, no app server, no per-request compute —
so hosting is close to free and there's almost nothing to maintain or secure.

Rough monthly cost for a small library site like this one:

| Item | Typical cost |
|------|--------------|
| Domain name | ~$1/mo (billed ~$12/yr) |
| Object storage (S3) for a few hundred MB | a few cents |
| CDN (CloudFront) egress at low traffic | often within the free tier; cents beyond |
| Build/deploy (GitHub Actions) | free for public repos |
| **Total** | **~$1–3/month** |

Compare that to a hosted ILS or a CMS on an always-on server (databases, backups,
upgrades, security patching). You can also host the exact same `public/` folder for **$0**
on GitHub Pages, Cloudflare Pages, or Netlify.

Because it's static, it's also fast and resilient: pages are pre-rendered and cached at
the edge, and there's no server to fall over under load.

## You don't need to be a developer to edit it

Day-to-day edits are just **Markdown** — the same simple formatting used across the web:

```markdown
## New Saturday hours

Starting in June we're open until **6pm** on Saturdays.
See the [events page](/events/) for details.
```

To add an event, you copy a file into `content/events/`, change the title and date, and
save. To publish, you need only a handful of **Git** commands — the same three every time:

```bash
git add .
git commit -m "Add June hours notice"
git push
```

That `push` triggers the automated build and deploy. That's the whole skill set: edit
Markdown, run three commands. Many library staff already have this, and it's very
teachable.

## Prefer not to touch Git? Use a CMS.

For staff who'd rather not use the command line, a **git-based CMS** gives a friendly
editing screen in the browser while still saving to the same repository — so you keep the
cheap, static, no-lock-in setup.

This demo includes a [**Sveltia CMS**](https://github.com/sveltia/sveltia-cms) admin at
[`/admin/`](/admin/). It presents forms for events and pages; when connected to the
repository (via a GitHub login), *Save* writes the Markdown and commits it for you — no
Git knowledge required.

> The `/admin/` here is a scaffold: the editing UI loads and shows the collections, but
> writing needs a one-time OAuth backend setup for the repo. It's here to show the option,
> not to accept edits to this demo.

## The takeaway

A credible library website — pages, events, and a searchable catalog — can be built and
run by one person, for a dollar or two a month, edited in Markdown or a simple CMS. That's
the case this whole demo is making.

Back to [all guides](/docs/), or see it live: the [catalog](/works/) and
[events](/events/). There's a back room too: [try the cataloging
sandbox](/docs/cataloging-sandbox/).
