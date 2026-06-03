import assert from "node:assert";
import { createRequire } from "node:module";
const require = createRequire(import.meta.url);
const A = require("../package/contents/ui/cards/achievements.js");

// query(): includes the verified-safe fields, excludes the scope-gated ones.
const q = A.query();
assert.ok(q.indexOf("starredRepositories") !== -1, "has starred");
assert.ok(q.indexOf("pullRequestReviewContributions") !== -1, "has reviews");
assert.ok(q.indexOf("sponsorshipsAsSponsor") !== -1, "has sponsoring");
assert.ok(q.indexOf("packages") === -1, "no scope-gated packages");
assert.ok(q.indexOf("projects") === -1, "no deprecated projects");

// rank(): thresholds [c,b,a,s,m] = [1,20,50,100,250].
const T = [1, 20, 50, 100, 250];
assert.strictEqual(A.rank(0, T).rank, "X", "below c is locked");
assert.strictEqual(A.rank(1, T).rank, "C", "c boundary");
assert.strictEqual(A.rank(19, T).rank, "C");
assert.strictEqual(A.rank(20, T).rank, "B", "b boundary");
assert.strictEqual(A.rank(50, T).rank, "A", "a boundary");
assert.strictEqual(A.rank(100, T).rank, "S", "s boundary");
assert.strictEqual(A.rank(250, T).rank, "S");
assert.ok(Math.abs(A.rank(20, T).progress - 0) < 1e-9, "progress 0 at tier start");
assert.ok(Math.abs(A.rank(35, T).progress - 0.5) < 1e-9, "progress half through B");

// groupNum(): thousands grouping via regex.
assert.strictEqual(A.groupNum(0), "0");
assert.strictEqual(A.groupNum(999), "999");
assert.strictEqual(A.groupNum(1247), "1,247");
assert.strictEqual(A.groupNum(1000000), "1,000,000");

// plural(): default and custom suffixes.
assert.strictEqual(A.plural(1, "star"), "star");
assert.strictEqual(A.plural(2, "star"), "stars");
assert.strictEqual(A.plural(1, "repositor", "y", "ies"), "repository");
assert.strictEqual(A.plural(3, "repositor", "y", "ies"), "repositories");

// parse(): crafted viewer; pinned now for the Member age calc.
const now = Date.parse("2026-06-04T00:00:00Z");
const data = { viewer: {
  repositories: { totalCount: 42, nodes: [
    { forkCount: 600, primaryLanguage: { name: "Go" } },
    { forkCount: 10, primaryLanguage: { name: "JavaScript" } },
    { forkCount: 5, primaryLanguage: { name: "Go" } }
  ] },
  forks: { totalCount: 3 },
  pullRequests: { totalCount: 0 },
  contributionsCollection: { pullRequestReviewContributions: { totalCount: 210 } },
  gists: { totalCount: 0 },
  organizations: { totalCount: 1 },
  starredRepositories: { totalCount: 50 },
  followers: { totalCount: 318 },
  following: { totalCount: 0 },
  createdAt: "2020-01-01T00:00:00Z",
  sponsorshipsAsSponsor: { totalCount: 0 },
  discussionsStarted: { totalCount: 0 },
  discussionsComments: { totalCount: 0 },
  popular: { nodes: [ { stargazerCount: 1247 } ] }
} };
const m = A.parse(data, now);
function byId(id) { return m.achievements.filter(function(x){ return x.id === id; })[0]; }

// All 15 are kept now (locked ones shown greyed, like the metrics grid).
assert.strictEqual(m.achievements.length, 15, "all 15 achievements kept");

// Developer: 42 -> B. New presentation fields (prefix + per-rank colors, no octicon).
const dev = byId("developer");
assert.strictEqual(dev.rank, "B");
assert.strictEqual(dev.locked, false);
assert.strictEqual(dev.prefix, "Great");
assert.strictEqual(dev.value, 42);
assert.strictEqual(dev.description, "Published 42 public repositories");
assert.strictEqual(dev.titleColor, "#9D8FFF");
assert.strictEqual(dev.gaugeColor, "#9E91FF");
assert.strictEqual(dev.glyphPrimary, "#7D6CFF");
assert.strictEqual(dev.glyphSecondary, "#B2A8FF");
// Maintainer: 1247 stars -> B; comma-grouped.
assert.strictEqual(byId("maintainer").rank, "B");
assert.strictEqual(byId("maintainer").description, "Maintaining a repository with 1,247 stars");
// Inspirer: max forkCount 600 -> A; prefix "Super"; value carried.
assert.strictEqual(byId("inspirer").rank, "A");
assert.strictEqual(byId("inspirer").prefix, "Super");
assert.strictEqual(byId("inspirer").value, 600);
// Polyglot: 2 distinct primary langs -> C; no prefix; blue title.
assert.strictEqual(byId("polyglot").rank, "C");
assert.strictEqual(byId("polyglot").prefix, "");
assert.strictEqual(byId("polyglot").titleColor, "#58A6FF");
// Influencer 318 -> B; Reviewer 210 -> B.
assert.strictEqual(byId("influencer").rank, "B");
assert.strictEqual(byId("reviewer").rank, "B");
// Member: ~6.4y -> floor 6 -> A.
assert.strictEqual(byId("member").rank, "A");
assert.strictEqual(byId("member").value, 6);
assert.strictEqual(byId("member").description, "Registered 6 years ago");

// Locked achievements are KEPT (rank X, greyed), not removed.
const con = byId("contributor");
assert.strictEqual(con.rank, "X", "0 PRs -> locked X");
assert.strictEqual(con.locked, true);
assert.strictEqual(con.prefix, "");
assert.strictEqual(con.value, 0);
assert.strictEqual(con.titleColor, "#666666");
assert.strictEqual(con.gaugeColor, "#B0B0B0");
assert.ok(byId("gister") && byId("follower") && byId("sponsor") && byId("chatter"),
  "other zero-value achievements are present (locked), not dropped");

// Sorted best-first; locked (X) sink to the end.
const ord = { S: 4, A: 3, B: 2, C: 1, X: 0 };
for (let i = 1; i < m.achievements.length; i++) {
  const prev = ord[m.achievements[i-1].rank] + m.achievements[i-1].progress * 0.99;
  const cur = ord[m.achievements[i].rank] + m.achievements[i].progress * 0.99;
  assert.ok(prev >= cur - 1e-9, "sorted descending by rank+progress");
}
assert.strictEqual(m.achievements[m.achievements.length - 1].rank, "X", "locked sort last");

// progress is clamped to [0,1] for the gauge arc.
assert.ok(m.achievements.every(function(x){ return x.progress >= 0 && x.progress <= 1; }), "progress clamped");

// All-zero / brand-new account -> all 15 present, all locked.
const zero = A.parse({ viewer: {
  repositories: { totalCount: 0, nodes: [] }, forks: { totalCount: 0 },
  pullRequests: { totalCount: 0 },
  contributionsCollection: { pullRequestReviewContributions: { totalCount: 0 } },
  gists: { totalCount: 0 }, organizations: { totalCount: 0 },
  starredRepositories: { totalCount: 0 }, followers: { totalCount: 0 },
  following: { totalCount: 0 }, createdAt: "2026-06-04T00:00:00Z",
  sponsorshipsAsSponsor: { totalCount: 0 }, discussionsStarted: { totalCount: 0 },
  discussionsComments: { totalCount: 0 }, popular: { nodes: [] }
} }, now);
assert.strictEqual(zero.achievements.length, 15, "all kept on empty account");
assert.ok(zero.achievements.every(function(x){ return x.locked; }), "all locked on empty account");

// rank() C-tier progress uses its own denominator (t[1]-t[0]).
assert.ok(Math.abs(A.rank(10, T).progress - (10 - 1) / (20 - 1)) < 1e-9, "C-tier progress fraction");

// parse() tolerates a null contributionsCollection (Reviewer falls to 0 -> locked, still present).
const noCC = A.parse({ viewer: {
  repositories: { totalCount: 0, nodes: [] }, forks: { totalCount: 0 },
  pullRequests: { totalCount: 0 }, contributionsCollection: null,
  gists: { totalCount: 0 }, organizations: { totalCount: 0 },
  starredRepositories: { totalCount: 0 }, followers: { totalCount: 0 },
  following: { totalCount: 0 }, createdAt: "2026-06-04T00:00:00Z",
  sponsorshipsAsSponsor: { totalCount: 0 }, discussionsStarted: { totalCount: 0 },
  discussionsComments: { totalCount: 0 }, popular: { nodes: [] }
} }, now);
assert.strictEqual(noCC.achievements.filter(function(x){ return x.id === "reviewer"; })[0].rank, "X",
  "null contributionsCollection -> reviewer locked, no throw");

// parse() ignores repo nodes with a null primaryLanguage when counting Polyglot.
const nullLang = A.parse({ viewer: {
  repositories: { totalCount: 5, nodes: [
    { forkCount: 0, primaryLanguage: { name: "Rust" } },
    { forkCount: 0, primaryLanguage: null }
  ] },
  forks: { totalCount: 0 }, pullRequests: { totalCount: 0 },
  contributionsCollection: { pullRequestReviewContributions: { totalCount: 0 } },
  gists: { totalCount: 0 }, organizations: { totalCount: 0 },
  starredRepositories: { totalCount: 0 }, followers: { totalCount: 0 },
  following: { totalCount: 0 }, createdAt: "2026-06-04T00:00:00Z",
  sponsorshipsAsSponsor: { totalCount: 0 }, discussionsStarted: { totalCount: 0 },
  discussionsComments: { totalCount: 0 }, popular: { nodes: [] }
} }, now);
const poly = nullLang.achievements.filter(function(x){ return x.id === "polyglot"; })[0];
assert.strictEqual(poly.description, "Using 1 different programming language",
  "null primaryLanguage ignored; only 'Rust' counted; singular form");

console.log("ok - achievements.js");
