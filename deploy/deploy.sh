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

# css/js ride the SHORT bucket: their URLs are not fingerprinted (lcat.css and friends
# are linked plain by the module -- upstream tasks/123), so a long browser max-age
# serves stale styles against fresh HTML after every module bump (bit us live when
# hugo/v0.5.0 added .lcat-btn: cached lcat.css had no button styles).
echo "==> HTML + sitemap + css/js (short cache, must-revalidate)"
aws s3 sync "$BUILD_DIR/" "s3://$BUCKET/" \
  --exclude "*" --include "*.html" --include "sitemap.xml" \
  --include "*.css" --include "*.js" --exclude "pagefind/*" \
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
