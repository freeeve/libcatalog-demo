---
title: "Build and deploy it, step by step"
summary: "The actual commands: install, pull data, build, preview, and ship to a CDN."
weight: 20
---

These are the real commands behind this site. You need [Hugo (extended)](https://gohugo.io/installation/),
[Go](https://go.dev/dl/), and [Node](https://nodejs.org). Lines starting with `#` are
comments.

## 1. Get the code

```bash
git clone https://github.com/freeeve/libcatalog-demo
cd libcatalog-demo
# The catalog templates come from the libcatalog module; for local dev this repo
# resolves it from a sibling checkout (see go.mod). For CI it pins a published version.
git clone https://github.com/freeeve/libcatalog ../libcatalog
```

## 2. Build the catalog data

The catalog is generated from a Hardcover "read" shelf by the real libcatalog pipeline
(the `lcat` tool from the sibling checkout you cloned in step 1). Put your API token in
an env var (never commit it):

```bash
export HARDCOVER_API_TOKEN='...'   # Hardcover -> account settings -> API
npm run data:refresh               # lcat hardcover (ingest) -> lcat project (project)
```

That ingests the shelf into BIBFRAME records under `build/`, then projects them to
`assets/catalog.json` and `assets/facets.json` -- the two files the Hugo module reads.
It's safe to re-run any time; the projector owns the schema and the facet counts.
More detail (offline replay, how subjects get mapped): `scripts/README.md` in the repo.

## 3. Build the site

```bash
npm run build:full   # = hugo --minify  +  pagefind (full-text index)
```

The finished website is now in `public/` — a folder of static files.

## 4. Preview locally

```bash
hugo server          # http://localhost:1313
```

Edit a Markdown file under `content/` and the browser reloads instantly.

## 5. Deploy to a CDN

This demo runs on AWS S3 + CloudFront, defined as code under `deploy/terraform/`:

```bash
cd deploy/terraform
terraform init
terraform apply           # private S3 bucket + CloudFront + TLS cert + DNS
```

Then sync the built site and clear the CDN cache:

```bash
npm run build:full
BUCKET=<bucket> DISTRIBUTION_ID=<id> bash deploy/deploy.sh
```

`deploy.sh` uploads `public/`, sets sensible cache headers (short for HTML, long/immutable
for fingerprinted assets), and issues a CloudFront invalidation. On every push to `main`,
a GitHub Actions workflow does the same automatically using short-lived credentials (OIDC)
— no secrets stored in the repo.

## That's the whole loop

Write Markdown → `hugo` → upload `public/`. The catalog refreshes with one command when
you read more books. Next: [use your own data](/docs/use-your-own-data/),
[theme it](/docs/theming/), or read about
[what this costs to run](/docs/running-it/).
