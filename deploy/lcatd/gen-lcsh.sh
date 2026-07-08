#!/usr/bin/env bash
# gen-lcsh.sh -- (re)generate deploy/lcatd/lcsh.nq, the corpus-sized LCSH authority
# snapshot the cataloging demo bundles so its existing subjects render real headings
# instead of "shNNNN not in local index" (tasks/011). Harvests each LCSH subject the
# projected catalog uses from id.loc.gov via `lcat vocab-subset`. Run it after the
# catalog's subjects change (e.g. new books add new LCSH headings); commit the result.
#
#   deploy/lcatd/gen-lcsh.sh
#
# Requires a sibling ../libcat checkout (>= v0.4.2) and outbound internet (id.loc.gov).
#
# Scheme note: this demo's catalog subjects are https://id.loc.gov/... URIs (from the
# upstream ingest subject-map), while id.loc.gov's canonical identifier is http://. Since
# v0.4.2 `lcat vocab-subset` re-schemes in-namespace URIs to the catalog's form, so the
# snapshot is emitted https-keyed to match -- no post-processing needed (libcat
# tasks/100).
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
LCAT_DIR="$ROOT/../libcat"
CATALOG="$ROOT/assets/catalog.json"
OUT="$HERE/lcsh.nq"
NS="https://id.loc.gov/authorities/subjects/"

if [[ ! -f "$CATALOG" ]]; then
  echo "error: $CATALOG missing -- run 'npm run data:refresh' first" >&2; exit 1
fi

echo "==> harvesting LCSH subjects from id.loc.gov (via lcat vocab-subset)"
( cd "$LCAT_DIR" && go run ./cmd/lcat vocab-subset --catalog "$CATALOG" --out "$OUT" --namespace "$NS" )

echo "done: $OUT ($(grep -c 'prefLabel' "$OUT") prefLabels, $(wc -l < "$OUT" | tr -d ' ') quads)"
