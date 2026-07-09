# 028 -- bump-libcat-v0.100.1

Opened 2026-07-09.

Routine currency bump: libcat lockstep advanced v0.72.0 -> v0.100.1 (latest
published hugo tag) since the last demo deploy earlier today.

## Outcome

- `HUGO_MODULE_VERSION` repo variable set to v0.100.1.
- Module v0.100.1 still targets catalog schema 11 (same as v0.72.0), so no
  data doc changes. Reprojected build/catalog.nq with lcat v0.100.1
  (installed from the published tag -- sibling working tree had concurrent
  uncommitted work) and the output is byte-identical to the committed
  assets/catalog.json + facets.json (102 works) -- no data regression, no
  asset diff to commit.
- Deploy triggered by this task commit landing on main; CI pins hugo@v0.100.1.
- lcatd sandbox note from tasks/027 still applies only on a sandbox redeploy;
  not done here.
