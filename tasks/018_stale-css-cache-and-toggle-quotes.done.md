# 018 -- Fix: stale-CSS browser caching after module bumps; quoted toggle label

Two live issues reported after the v0.7.0 deploy (hugo/v0.5.0 hooks):

1. **Hero buttons invisible for returning visitors.** Not a regression in the new
   build -- deploy.sh served css/js with `max-age=86400` on UNfingerprinted URLs, so
   browsers held the pre-bump `lcat.css` (no `.lcat-btn` rules) against the new
   HTML for up to a day; the buttons fell through to bare-link styling (dim green
   on the dark hero). Fixed: css/js moved to the short bucket
   (`max-age=300,must-revalidate`) like HTML; img/icons keep 1 day. Proper fix is
   upstream fingerprinting of module-linked assets -- filed as libcatalog
   tasks/123; when that ships the long TTL can come back for hashed names.

2. **Theme toggle showed literal quotes ("Dark mode").** Module bug: paint() in
   theme-toggle.html interpolates `i18n ... | jsonify` in a <script> without
   safeJS, so html/template re-encodes the JSON string and the quotes land in
   textContent. Filed as libcatalog tasks/122; carrying a TEMPORARY one-line
   shadow (`layouts/_partials/theme-toggle.html`, adds `| safeJS`) until it ships
   -- the only shadow in the repo, marked DELETE-when-upstream-fixes.

Verified: rendered JS is `textContent=t?"Light mode":"Dark mode"` (clean string
literals); headless screenshot shows the unquoted label; sync filter order keeps
pagefind/* immutable and untouched by the short-TTL pass.
