#!/usr/bin/env node
/**
 * fetch-hardcover.mjs -- turn Eve's Hardcover "read" shelf into catalog.json (tasks/001).
 *
 * Reads the authenticated user's read books from the Hardcover GraphQL API and maps
 * them to the libcatalog projected schema (version 5) that the Hugo module consumes.
 * Controlled subjects are intentionally left to scripts/map-subjects.mjs (tasks/004):
 * this step only fills tags[] from Hardcover genres. After running this, run
 * `npm run data:build` to promote subjects and regenerate facets.json.
 *
 *   HARDCOVER_TOKEN=... node scripts/fetch-hardcover.mjs            # write assets/catalog.json
 *   HARDCOVER_TOKEN=... node scripts/fetch-hardcover.mjs --introspect user_books
 *   HARDCOVER_TOKEN=... node scripts/fetch-hardcover.mjs --out /tmp/catalog.json --limit 50
 *
 * The token comes from Hardcover account settings -> API and MUST stay out of the repo
 * (env var only). Hardcover's GraphQL schema evolves; if a field below has moved, use
 * --introspect to confirm the current shape, then adjust the query. The mapping uses
 * optional chaining throughout so a missing field degrades to omitted rather than
 * crashing. Preferred future path (tasks/001 §3): for records whose ISBN resolves to a
 * real MARC/BIBFRAME record, run that through `lcat project` instead of this direct
 * map, so the demo exercises the genuine BIBFRAME -> project pipeline; this direct
 * mapping is the documented fallback for records with no retrievable bib record.
 */
import { writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";

const HERE = dirname(fileURLToPath(import.meta.url));
const ENDPOINT = "https://api.hardcover.app/v1/graphql";
const READ_STATUS_ID = 3; // Hardcover status_id: 1=Want to Read, 2=Currently Reading, 3=Read.

const args = parseArgs(process.argv.slice(2));
const token = normalizeToken(process.env.HARDCOVER_TOKEN);
if (!token) {
  console.error(
    "HARDCOVER_TOKEN is not set. Get a token from Hardcover -> account settings -> API\n" +
      "and export it (do not commit it):  export HARDCOVER_TOKEN='...'"
  );
  process.exit(2);
}

/** Parse `--flag value` / `--flag` argv into an object. */
function parseArgs(argv) {
  const out = { limit: 100 };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--introspect") out.introspect = argv[i + 1] && !argv[i + 1].startsWith("--") ? argv[++i] : "query_root";
    else if (a === "--out") out.out = argv[++i];
    else if (a === "--limit") out.limit = Number(argv[++i]) || 100;
  }
  return out;
}

/** Accept a raw token or one that already carries a "Bearer " prefix. */
function normalizeToken(t) {
  if (!t) return null;
  return t.trim().replace(/^Bearer\s+/i, "");
}

/** POST a GraphQL query and return `data`, throwing on transport or GraphQL errors. */
async function gql(query, variables = {}) {
  const res = await fetch(ENDPOINT, {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
    body: JSON.stringify({ query, variables }),
  });
  if (!res.ok) throw new Error(`HTTP ${res.status} ${res.statusText}: ${await res.text()}`);
  const body = await res.json();
  if (body.errors) throw new Error("GraphQL errors: " + JSON.stringify(body.errors));
  return body.data;
}

/** Dump a type's fields so the caller can confirm the live schema shape. */
async function introspect(typeName) {
  const data = await gql(
    `query I($n:String!){ __type(name:$n){ name kind fields{ name type{ name kind ofType{ name kind } } } } }`,
    { n: typeName }
  );
  console.log(JSON.stringify(data.__type, null, 2));
}

/**
 * Convert a display name ("First Middle Last") to catalog form ("Last, First Middle").
 * Heuristic: names already containing a comma, or single-token names, pass through.
 * Compound surnames (e.g. "Ursula K. Le Guin") are not detected -- maintain an override
 * map here if the read shelf needs it.
 * @param {string} name
 */
function lastFirst(name) {
  const n = (name || "").trim();
  if (!n || n.includes(",")) return n;
  const parts = n.split(/\s+/);
  if (parts.length < 2) return n;
  const last = parts.pop();
  return `${last}, ${parts.join(" ")}`;
}

/** Map a Hardcover reading_format_id / format string to a libcatalog format token. */
function formatOf(edition) {
  const byId = { 1: "physical", 2: "audiobook", 4: "ebook" };
  if (edition?.reading_format_id != null && byId[edition.reading_format_id]) return byId[edition.reading_format_id];
  const f = (edition?.reading_format || edition?.format || "").toLowerCase();
  if (f.includes("audio")) return "audiobook";
  if (f.includes("e-book") || f.includes("ebook") || f.includes("kindle")) return "ebook";
  if (f) return "physical";
  return undefined;
}

/** Collect a book's genre strings from Hardcover's cached_tags JSON (Genre category). */
function genresOf(book) {
  const ct = book?.cached_tags;
  const tags = typeof ct === "string" ? safeJson(ct) : ct;
  const genre = tags?.Genre || tags?.genre || [];
  return [...new Set(genre.map((g) => (typeof g === "string" ? g : g?.tag)).filter(Boolean))];
}

function safeJson(s) {
  try {
    return JSON.parse(s);
  } catch {
    return null;
  }
}

/** Build a stable Work id from the Hardcover book (slug preferred, id as fallback). */
function workId(book) {
  const slug = (book?.slug || "").replace(/[^a-z0-9]+/gi, "").toLowerCase();
  return "w" + (slug || String(book?.id));
}

/**
 * Map one Hardcover user_book to a catalog Work (schema v5). Extra fields the module's
 * adopter templates use (cover, rating, dateRead) ride alongside the core schema.
 * @param {object} ub a user_books row with nested `book`
 */
function toWork(ub) {
  const book = ub.book || {};
  const editions = (book.editions || []).filter(Boolean);
  const instances = editions.map((e, i) => {
    const isbns = [e.isbn_13, e.isbn_10].filter(Boolean);
    return { id: `i${book.id}e${e.id ?? i}`, format: formatOf(e), ...(isbns.length ? { isbns } : {}) };
  });
  const contributors = (book.contributions || [])
    .map((c) => {
      const name = c?.author?.name;
      if (!name) return null;
      return { name: lastFirst(name), role: (c.contribution || "author").toLowerCase() };
    })
    .filter(Boolean);
  const formats = [...new Set(instances.map((i) => i.format).filter(Boolean))];

  const work = {
    id: workId(book),
    title: book.title,
    ...(book.subtitle ? { subtitle: book.subtitle } : {}),
    contributors: contributors.length ? contributors : [{ name: "Unknown" }],
    tags: genresOf(book),
    languages: ["eng"], // Hardcover rarely exposes language; default to eng (tasks/001 §2).
    formats,
    instances: instances.length ? instances : [{ id: `i${book.id}`, format: undefined }],
  };
  if (book.description) work.description = book.description;
  const cover = book.image?.url || editions.find((e) => e.image?.url)?.image?.url;
  if (cover) work.cover = cover;
  if (ub.rating != null) work.rating = ub.rating;
  const dateRead = (ub.user_book_reads || []).map((r) => r?.finished_at).filter(Boolean).sort().pop();
  if (dateRead) work.dateRead = dateRead;
  return work;
}

const READ_SHELF_QUERY = `
query ReadShelf($limit:Int!, $offset:Int!) {
  me { id }
  user_books(
    where: { status_id: { _eq: ${READ_STATUS_ID} } }
    order_by: { id: asc }
    limit: $limit
    offset: $offset
  ) {
    id
    rating
    user_book_reads { finished_at }
    book {
      id
      slug
      title
      subtitle
      description
      image { url }
      contributions { contribution author { name } }
      cached_tags
      editions {
        id
        isbn_13
        isbn_10
        reading_format_id
        reading_format
        image { url }
      }
    }
  }
}`;

/** Page through the whole read shelf and return mapped Works. */
async function fetchAllWorks() {
  const works = [];
  const seen = new Set();
  for (let offset = 0; ; offset += args.limit) {
    const data = await gql(READ_SHELF_QUERY, { limit: args.limit, offset });
    const rows = data.user_books || [];
    for (const ub of rows) {
      if (!ub.book?.title) continue;
      const w = toWork(ub);
      if (seen.has(w.id)) continue; // clustering by book id de-dupes multi-edition reads.
      seen.add(w.id);
      works.push(w);
    }
    process.stderr.write(`\rfetched ${works.length} works...`);
    if (rows.length < args.limit) break;
  }
  process.stderr.write("\n");
  return works;
}

async function main() {
  if (args.introspect) return introspect(args.introspect);
  const works = await fetchAllWorks();
  works.sort((a, b) => (a.title || "").localeCompare(b.title || "", "en"));
  const out = args.out || resolve(HERE, "../assets/catalog.json");
  writeFileSync(out, JSON.stringify({ version: 5, works }, null, 2) + "\n");
  console.log(`wrote ${works.length} works to ${out}. Next: npm run data:build (subjects + facets).`);
}

main().catch((e) => {
  console.error("\nfetch-hardcover failed:", e.message);
  process.exit(1);
});
