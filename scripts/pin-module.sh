#!/usr/bin/env bash
# pin-module.sh -- swap the local sibling `replace` for a published module version so
# CI (which has no ../libcatalog checkout) resolves the Hugo module from the Go proxy
# (tasks/003 §3). Run in CI before `hugo`; do NOT commit the result to main -- local
# dev keeps the replace.
#
#   scripts/pin-module.sh v0.1.0
#   HUGO_MODULE_VERSION=v0.1.0 scripts/pin-module.sh
#
# VERSION is the module semver (e.g. v0.1.0). Because the module lives in the repo's
# hugo/ subdirectory, its git tag is prefixed (`hugo/v0.1.0`); Go maps @v0.1.0 to that
# tag automatically -- pass the unprefixed version here.
#
# Prerequisite: the module must be published -- tag github.com/freeeve/libcatalog/hugo
# in the libcatalog repo (e.g. `git tag hugo/v0.1.0 && git push origin hugo/v0.1.0`) or
# supply a pseudo-version. Until then `go mod download` fails fast with a proxy error.
set -euo pipefail

MOD="github.com/freeeve/libcatalog/hugo"
VERSION="${1:-${HUGO_MODULE_VERSION:-}}"
if [[ -z "$VERSION" ]]; then
  echo "usage: $0 <version|pseudo-version>  (or set HUGO_MODULE_VERSION)" >&2
  exit 2
fi

# Set the require and drop the replace in one edit. Do NOT `go get`/`go mod tidy`: the
# demo imports the module only as a Hugo module (no Go package imports it), so `go get`
# fails to resolve the placeholder v0.0.0 require and `go mod tidy` would prune the
# require entirely. `go mod download` fetches the pinned version and writes go.sum.
go mod edit -dropreplace="$MOD" -require="$MOD@$VERSION"
go mod download "$MOD"
echo "pinned $MOD@$VERSION (replace dropped)"
