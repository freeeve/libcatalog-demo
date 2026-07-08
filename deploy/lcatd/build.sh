#!/usr/bin/env bash
# build.sh -- produce the lcatd-lambda deployment zip for the read-only cataloging
# demo (tasks/009): the arm64 `bootstrap` binary (with the SPA embedded) plus the
# bundled BIBFRAME grain tree the read-only backend serves.
#
#   deploy/lcatd/build.sh            # -> deploy/lcatd/dist/lcatd-demo.zip
#
# Requires a sibling ../libcat checkout (Go 1.25+, Node for the SPA build) and the
# grain tree under this repo's build/ (produced by `npm run data:refresh`, tasks/008).
# The zip is grains-in-image + in-memory store, so the Lambda needs no S3/DynamoDB.
#
# SPA note (libcat tasks/098): the module's committed ui/dist is a placeholder; a
# real UI only exists after `npm run build`. This runs it before `go build`, then
# restores the sibling's tracked dist/index.html so the sibling working tree is left as
# found (dist/assets is gitignored).
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
BACKEND="$ROOT/../libcat/backend"
GRAINS="$ROOT/build"                 # build/data/works/<shard>/<id>.nq
OUT="$HERE/dist"
STAGE="$OUT/stage"

if [[ ! -d "$BACKEND/cmd/lcatd-lambda" ]]; then
  echo "error: sibling libcat backend not found at $BACKEND" >&2; exit 1
fi
if [[ ! -d "$GRAINS/data/works" ]]; then
  echo "error: grain tree missing at $GRAINS/data/works -- run 'npm run data:refresh' first" >&2; exit 1
fi

echo "==> building the cataloging SPA (so go:embed picks up the real app)"
restore_dist() { git -C "$BACKEND/.." checkout -- backend/ui/dist/index.html 2>/dev/null || true; }
trap restore_dist EXIT
( cd "$BACKEND/ui" && npm ci --silent && npm run build >/dev/null )

echo "==> building bootstrap (linux/arm64, provided.al2023)"
( cd "$BACKEND" && GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o "$STAGE/bootstrap" ./cmd/lcatd-lambda )

echo "==> staging bundled grains"
rm -rf "$STAGE/grains"
mkdir -p "$STAGE/grains/data"
cp -R "$GRAINS/data/works" "$STAGE/grains/data/works"
[[ -d "$GRAINS/data/authorities" ]] && cp -R "$GRAINS/data/authorities" "$STAGE/grains/data/authorities" || true

# Authority snapshots (tasks/011 + 020) so the sandbox renders existing subjects'
# real headings: lcsh.nq is a corpus-sized subset (regen: gen-lcsh.sh when the
# catalog's subjects change); homosaurus.nq is the FULL vocabulary (small enough to
# ship whole -- the picker searches all of it locally; regen: gen-homosaurus.sh on
# new Homosaurus releases). Schemes enabled via LCATD_VOCAB_SCHEMES in main.tf.
mkdir -p "$STAGE/grains/data/authorities/vocab"
cp "$HERE/lcsh.nq" "$STAGE/grains/data/authorities/vocab/lcsh.nq"
cp "$HERE/homosaurus.nq" "$STAGE/grains/data/authorities/vocab/homosaurus.nq"

echo "==> zipping"
rm -f "$OUT/lcatd-demo.zip"
( cd "$STAGE" && zip -qr "$OUT/lcatd-demo.zip" bootstrap grains )

echo "done: $OUT/lcatd-demo.zip"
( cd "$STAGE" && echo "  bootstrap: $(du -h bootstrap | cut -f1) | grains: $(find grains -name '*.nq' | wc -l | tr -d ' ') work grains" )
