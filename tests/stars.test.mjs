import assert from "node:assert";
import { createRequire } from "node:module";
const require = createRequire(import.meta.url);
const Stars = require("../package/contents/ui/cards/stars.js");

// query() interpolates the limit and asks for newest-first.
const q = Stars.query(3);
assert.ok(q.indexOf("first: 3") !== -1, "query uses the limit");
assert.ok(q.indexOf("STARRED_AT") !== -1 && q.indexOf("DESC") !== -1, "newest first");
assert.ok(q.indexOf("issues(states: OPEN)") !== -1, "open issues only");
assert.ok(q.indexOf("pullRequests(states: OPEN)") !== -1, "open PRs only");
assert.strictEqual(Stars.query().indexOf("first: 3") !== -1, true, "defaults to 3");
assert.ok(Stars.query(0).indexOf("first: 1") !== -1, "clamps to at least 1");

// compact() formats counts GitHub-style.
assert.strictEqual(Stars.compact(999), "999", "below 1000 as-is");
assert.strictEqual(Stars.compact(1000), "1k", "exactly 1000");
assert.strictEqual(Stars.compact(7420), "7.42k", "two decimals");
assert.strictEqual(Stars.compact(23000), "23k", "trailing zeros trimmed");
assert.strictEqual(Stars.compact(1500000), "1.5m", "millions");
assert.strictEqual(Stars.compact(0), "0", "zero");
assert.strictEqual(Stars.compact(999999), "1m", "rounds up past the k unit");

// relTime() — pinned now so it's deterministic.
const now = Date.parse("2026-06-03T12:00:00Z");
assert.strictEqual(Stars.relTime("2026-06-03T09:00:00Z", now), "starred 3 hours ago");
assert.strictEqual(Stars.relTime("2026-06-03T11:00:00Z", now), "starred 1 hour ago");
assert.strictEqual(Stars.relTime("2026-05-30T12:00:00Z", now), "starred 4 days ago");
assert.strictEqual(Stars.relTime("2026-06-02T12:00:00Z", now), "starred 1 day ago");
assert.strictEqual(Stars.relTime("2026-05-05T12:00:00Z", now), "starred 29 days ago");
assert.strictEqual(Stars.relTime("2026-05-04T12:00:00Z", now), "starred 4 weeks ago");
assert.strictEqual(Stars.relTime("2026-04-20T12:00:00Z", now), "starred 6 weeks ago");

// parse() — full row + a row with null language/license and empty description.
const data = { viewer: { starredRepositories: { edges: [
  { starredAt: "2026-05-30T12:00:00Z", node: {
      url: "https://github.com/a/b", nameWithOwner: "a/b", description: "Hello",
      stargazerCount: 7420, forkCount: 785,
      primaryLanguage: { name: "JavaScript", color: "#f1e05a" },
      licenseInfo: { nickname: null, spdxId: "MIT" },
      issues: { totalCount: 333 }, pullRequests: { totalCount: 184 } } },
  { starredAt: "2026-06-03T09:00:00Z", node: {
      url: "https://github.com/c/d", nameWithOwner: "c/d", description: null,
      stargazerCount: 12, forkCount: 0,
      primaryLanguage: null, licenseInfo: null,
      issues: { totalCount: 0 }, pullRequests: { totalCount: 0 } } }
] } } };
const m = Stars.parse(data, now);
assert.strictEqual(m.repos.length, 2, "two repos");
const r0 = m.repos[0];
assert.strictEqual(r0.name, "a/b");
assert.strictEqual(r0.url, "https://github.com/a/b");
assert.strictEqual(r0.description, "Hello");
assert.strictEqual(r0.starsText, "7.42k");
assert.strictEqual(r0.forksText, "785");
assert.strictEqual(r0.issuesText, "333");
assert.strictEqual(r0.prsText, "184");
assert.strictEqual(r0.language, "JavaScript");
assert.strictEqual(r0.languageColor, "#f1e05a");
assert.strictEqual(r0.license, "MIT", "falls back to spdxId when nickname is null");
assert.strictEqual(r0.starred, "starred 4 days ago");
const r1 = m.repos[1];
assert.strictEqual(r1.description, "", "null description becomes empty string");
assert.strictEqual(r1.language, null, "null primaryLanguage stays null");
assert.strictEqual(r1.languageColor, null);
assert.strictEqual(r1.license, null, "null licenseInfo stays null");

// Empty edges -> empty list.
const empty = Stars.parse({ viewer: { starredRepositories: { edges: [] } } }, now);
assert.strictEqual(empty.repos.length, 0);

console.log("ok - stars.js");
