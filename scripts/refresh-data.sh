#!/usr/bin/env bash
# refresh-data.sh -- regenerate assets/catalog.json + facets.json from Eve's Hardcover
# "Read" shelf via the real libcatalog pipeline (tasks/008):
#
#   Hardcover Read shelf --(lcat hardcover)--> BIBFRAME grains + catalog.nq  (build/)
#                        --(lcat project)-----> catalog.json + facets.json   (schema v7)
#
# This replaces the old hand-rolled Node pipeline (scripts/*.mjs). Controlled subjects,
# facet counts, the cover/rating/dateRead extras, and the schema version are all owned by
# the projector now -- the next schema bump is a re-run of this script, not a hand-edit.
#
# Requires a sibling ../libcatalog checkout (Go 1.25+) and HARDCOVER_API_TOKEN
# (Hardcover -> account settings -> API; never commit it). Extra flags are forwarded to
# `lcat hardcover`, so a captured shelf can be replayed offline without a token:
#
#   scripts/refresh-data.sh                       # live fetch (needs HARDCOVER_API_TOKEN)
#   scripts/refresh-data.sh --source shelf.json   # offline replay of a captured shelf
#
# To reproject an existing graph without re-fetching (e.g. after a schema bump, when
# build/catalog.nq is still present):
#
#   (cd ../libcatalog && go run ./cmd/lcat project \
#      --catalog "$OLDPWD/build/catalog.nq" --provider hardcover --out "$OLDPWD/build/projected")
#   cp build/projected/{catalog,facets}.json assets/
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
MODULE="$ROOT/../libcatalog"
BUILD="$ROOT/build"

if [[ ! -d "$MODULE/cmd/lcat" ]]; then
  echo "error: sibling libcatalog checkout not found at $MODULE (needed for lcat)" >&2
  exit 1
fi

lcat() { (cd "$MODULE" && go run ./cmd/lcat "$@"); }

mkdir -p "$BUILD"
echo "==> lcat hardcover: ingesting Read shelf -> $BUILD"
lcat hardcover --out "$BUILD" "$@"

echo "==> lcat project: -> assets/ (schema v7)"
lcat project --catalog "$BUILD/catalog.nq" --provider hardcover --out "$BUILD/projected"
cp "$BUILD/projected/catalog.json" "$BUILD/projected/facets.json" "$ROOT/assets/"

echo "done: assets/catalog.json + assets/facets.json regenerated (schema v7)."
