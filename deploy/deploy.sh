#!/usr/bin/env bash
# deploy.sh -- sync a built site to S3 with correct content-types + cache headers and
# invalidate CloudFront (tasks/003 §2). Assumes `public/` is already built + indexed
# (npm run build:full). Works locally (with AWS creds) or from CI. Required env:
#   BUCKET            S3 origin bucket (terraform output bucket_name)
#   DISTRIBUTION_ID   CloudFront distribution id (terraform output distribution_id)
# Optional: BUILD_DIR (default public), INVALIDATE_PATHS (default /*).
set -euo pipefail

: "${BUCKET:?set BUCKET (terraform output bucket_name)}"
: "${DISTRIBUTION_ID:?set DISTRIBUTION_ID (terraform output distribution_id)}"
BUILD_DIR="${BUILD_DIR:-public}"
INVALIDATE_PATHS="${INVALIDATE_PATHS:-/*}"

if [[ ! -f "$BUILD_DIR/index.html" ]]; then
  echo "no $BUILD_DIR/index.html -- run 'npm run build:full' first" >&2
  exit 1
fi

echo "==> Pagefind assets (content-addressed -> immutable)"
aws s3 sync "$BUILD_DIR/pagefind/" "s3://$BUCKET/pagefind/" \
  --cache-control "public,max-age=31536000,immutable" --no-progress
# aws-cli's mimetypes can mislabel .wasm; set it explicitly so browsers stream-compile.
aws s3 cp "$BUILD_DIR/pagefind/" "s3://$BUCKET/pagefind/" --recursive \
  --exclude "*" --include "*.wasm" --content-type "application/wasm" \
  --cache-control "public,max-age=31536000,immutable" --metadata-directive REPLACE --no-progress || true

echo "==> Static assets (img/icons -> 1 day)"
aws s3 sync "$BUILD_DIR/" "s3://$BUCKET/" \
  --exclude "*.html" --exclude "pagefind/*" --exclude "sitemap.xml" --exclude "*.webmanifest" \
  --exclude "*.css" --exclude "*.js" \
  --cache-control "public,max-age=86400" --no-progress

# css/js are content-hashed since hugo/v0.6.0 (module assets upstream tasks/123, the
# site stylesheet via head-extra.html) -- upgrades change the URL, so immutable is
# safe. The v0.5.0 stale-CSS incident (tasks/018) cannot recur: old HTML references
# old hashes, new HTML references new ones.
echo "==> css/js (content-hashed -> immutable)"
aws s3 sync "$BUILD_DIR/" "s3://$BUCKET/" \
  --exclude "*" --include "*.css" --include "*.js" --exclude "pagefind/*" \
  --cache-control "public,max-age=31536000,immutable" --no-progress

# The shared facet sidebar (module tasks/150, ours tasks/025) publishes fingerprinted
# HTML fragments under /lcat/ -- extension-based rules would undercache them, so pin
# them immutable before the catch-all *.html rule below (which excludes lcat/).
echo "==> Shared sidebar fragments (fingerprinted -> immutable)"
aws s3 sync "$BUILD_DIR/" "s3://$BUCKET/" \
  --exclude "*" --include "lcat/*.html" \
  --cache-control "public,max-age=31536000,immutable" --no-progress

echo "==> HTML + sitemap (short cache, must-revalidate)"
aws s3 sync "$BUILD_DIR/" "s3://$BUCKET/" \
  --exclude "*" --include "*.html" --exclude "lcat/*.html" --include "sitemap.xml" \
  --cache-control "public,max-age=300,must-revalidate" --no-progress
if [[ -f "$BUILD_DIR/site.webmanifest" ]]; then
  aws s3 cp "$BUILD_DIR/site.webmanifest" "s3://$BUCKET/site.webmanifest" \
    --content-type "application/manifest+json" --cache-control "public,max-age=300" --no-progress
fi

echo "==> Prune removed objects (size-only keeps the cache headers set above)"
aws s3 sync "$BUILD_DIR/" "s3://$BUCKET/" --delete --size-only --no-progress

echo "==> Invalidate CloudFront $DISTRIBUTION_ID ($INVALIDATE_PATHS)"
aws cloudfront create-invalidation --distribution-id "$DISTRIBUTION_ID" --paths "$INVALIDATE_PATHS" \
  --query 'Invalidation.Id' --output text

echo "done."
