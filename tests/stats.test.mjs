import assert from "node:assert";
import { createRequire } from "node:module";
const require = createRequire(import.meta.url);
const Stats = require("../package/contents/ui/cards/stats.js");

assert.ok(Stats.query().indexOf("totalCommitContributions") !== -1, "query asks commits");
assert.ok(Stats.query().indexOf("stargazerCount") !== -1, "query asks stars");
assert.ok(Stats.query().indexOf("sponsors { totalCount }") !== -1, "query asks sponsors");
assert.ok(Stats.query().indexOf("sponsoring { totalCount }") !== -1, "query asks sponsoring");
assert.ok(Stats.query().indexOf("gists { totalCount }") !== -1, "query asks gists");
assert.ok(Stats.query().indexOf("organizations { totalCount }") !== -1, "query asks organizations");

const data = { viewer: {
    contributionsCollection: { totalCommitContributions: 1851 },
    pullRequests: { totalCount: 89 },
    issues: { totalCount: 23 },
    sponsors: { totalCount: 4 },
    sponsoring: { totalCount: 2 },
    gists: { totalCount: 7 },
    organizations: { totalCount: 5 },
    repositories: { nodes: [ { stargazerCount: 100 }, { stargazerCount: 34 }, { stargazerCount: 0 } ] }
} };
const m = Stats.parse(data);
assert.strictEqual(m.commits, 1851, "commits");
assert.strictEqual(m.prs, 89, "prs");
assert.strictEqual(m.issues, 23, "issues");
assert.strictEqual(m.stars, 134, "stars summed across repos");
assert.strictEqual(m.sponsors, 4, "sponsors");
assert.strictEqual(m.sponsoring, 2, "sponsoring");
assert.strictEqual(m.gists, 7, "gists");
assert.strictEqual(m.orgs, 5, "organizations");

const m2 = Stats.parse({ viewer: {
    contributionsCollection: { totalCommitContributions: 0 },
    pullRequests: { totalCount: 0 }, issues: { totalCount: 0 },
    sponsors: { totalCount: 0 }, sponsoring: { totalCount: 0 },
    gists: { totalCount: 0 }, organizations: { totalCount: 0 },
    repositories: { nodes: [] }
} });
assert.strictEqual(m2.stars, 0, "no repos → 0 stars");

console.log("ok - stats.js");
