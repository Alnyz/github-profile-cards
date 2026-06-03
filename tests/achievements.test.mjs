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

// Developer: 42 -> B (>=20, <50).
assert.strictEqual(byId("developer").rank, "B");
assert.strictEqual(byId("developer").rankColor, "#7D6CFF");
assert.strictEqual(byId("developer").description, "Published 42 public repositories");
assert.strictEqual(byId("developer").icon, "repo");
// Maintainer: 1247 stars -> B; comma-grouped, singular/plural correct.
assert.strictEqual(byId("maintainer").rank, "B");
assert.strictEqual(byId("maintainer").description, "Maintaining a repository with 1,247 stars");
// Inspirer: max forkCount 600 -> A (>=500).
assert.strictEqual(byId("inspirer").rank, "A");
assert.strictEqual(byId("inspirer").description, "A repository forked 600 times");
// Polyglot: distinct primary langs {Go, JavaScript} = 2 -> C.
assert.strictEqual(byId("polyglot").rank, "C");
assert.strictEqual(byId("polyglot").description, "Using 2 different programming languages");
// Influencer: 318 -> B.
assert.strictEqual(byId("influencer").rank, "B");
// Reviewer: 210 -> B.
assert.strictEqual(byId("reviewer").rank, "B");
// Member: 2020-01-01 -> 2026-06-04 ~ 6.4y -> floor 6 -> A (>=5).
assert.strictEqual(byId("member").rank, "A");
assert.strictEqual(byId("member").description, "Registered 6 years ago");
// Locked ones are filtered out entirely.
assert.strictEqual(byId("contributor"), undefined, "0 PRs -> locked -> absent");
assert.strictEqual(byId("gister"), undefined, "0 gists -> absent");
assert.strictEqual(byId("follower"), undefined, "0 following -> absent");
assert.strictEqual(byId("sponsor"), undefined);
assert.strictEqual(byId("chatter"), undefined);
// Sorted best-first: first entry has the highest order+progress; no X ranks present.
assert.ok(m.achievements.every(function(x){ return x.rank !== "X"; }), "no locked in output");
const ord = { S: 4, A: 3, B: 2, C: 1 };
for (var i = 1; i < m.achievements.length; i++) {
  const prev = ord[m.achievements[i-1].rank] + m.achievements[i-1].progress * 0.99;
  const cur = ord[m.achievements[i].rank] + m.achievements[i].progress * 0.99;
  assert.ok(prev >= cur - 1e-9, "sorted descending by rank+progress");
}

// All-zero data -> empty list.
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
assert.strictEqual(zero.achievements.length, 0, "nothing unlocked");

// rank() C-tier progress uses its own denominator (t[1]-t[0]).
assert.ok(Math.abs(A.rank(10, T).progress - (10 - 1) / (20 - 1)) < 1e-9, "C-tier progress fraction");

// parse() tolerates a null contributionsCollection (Reviewer falls to 0 -> locked).
const noCC = A.parse({ viewer: {
  repositories: { totalCount: 0, nodes: [] }, forks: { totalCount: 0 },
  pullRequests: { totalCount: 0 }, contributionsCollection: null,
  gists: { totalCount: 0 }, organizations: { totalCount: 0 },
  starredRepositories: { totalCount: 0 }, followers: { totalCount: 0 },
  following: { totalCount: 0 }, createdAt: "2026-06-04T00:00:00Z",
  sponsorshipsAsSponsor: { totalCount: 0 }, discussionsStarted: { totalCount: 0 },
  discussionsComments: { totalCount: 0 }, popular: { nodes: [] }
} }, now);
assert.strictEqual(noCC.achievements.filter(function(x){ return x.id === "reviewer"; })[0], undefined,
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
