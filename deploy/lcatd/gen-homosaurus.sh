#!/usr/bin/env bash
# gen-homosaurus.sh -- (re)generate deploy/lcatd/homosaurus.nq, the FULL Homosaurus
# vocabulary snapshot the cataloging demo bundles (tasks/020). Unlike LCSH (millions
# of headings -> corpus subset via gen-lcsh.sh), Homosaurus is small enough to ship
# whole, so the sandbox's subject picker can search every term locally -- no live
# proxy needed. Re-run when Homosaurus publishes a new release; commit the result.
#
#   deploy/lcatd/gen-homosaurus.sh
#
# Source: the official n-triples dump at https://homosaurus.org/v3.nt (https-keyed,
# matching this catalog's subject URIs). We keep only the SKOS surface the lcatd
# vocab index reads (mirrors backend/vocabsrc keepPredicates / lcat vocab-subset
# subsetKeep) and tag every quad with the <authority:homosaurus> graph the index
# expects. lcat vocab-subset is not used here: it fetches per-term <uri>.skos.nt
# (an id.loc.gov convention) and a whole-vocabulary dump is one request instead of
# thousands (generalizing it is libcatalog tasks/124).
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="$HERE/homosaurus.nq"
DUMP_URL="https://homosaurus.org/v3.nt"
GRAPH="<authority:homosaurus>"

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

echo "==> downloading the Homosaurus v3 dump"
curl -fsSL "$DUMP_URL" -o "$TMP"

echo "==> filtering to the SKOS surface + tagging graph $GRAPH"
awk -v graph="$GRAPH" '
  $2 == "<http://www.w3.org/2004/02/skos/core#prefLabel>"  ||
  $2 == "<http://www.w3.org/2004/02/skos/core#altLabel>"   ||
  $2 == "<http://www.w3.org/2004/02/skos/core#definition>" ||
  $2 == "<http://www.w3.org/2004/02/skos/core#broader>"    ||
  $2 == "<http://www.w3.org/2004/02/skos/core#narrower>"   ||
  $2 == "<http://www.w3.org/2004/02/skos/core#related>"    ||
  $2 == "<http://www.w3.org/2004/02/skos/core#exactMatch>" ||
  $2 == "<http://www.w3.org/2004/02/skos/core#closeMatch>" ||
  $2 == "<http://www.w3.org/2000/01/rdf-schema#label>" {
    sub(/ \.[[:space:]]*$/, " " graph " .")
    print
  }
' "$TMP" > "$OUT"

echo "done: $OUT ($(grep -c 'prefLabel' "$OUT") prefLabels, $(wc -l < "$OUT" | tr -d ' ') quads)"