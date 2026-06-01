import assert from "node:assert";
import { createRequire } from "node:module";
const require = createRequire(import.meta.url);
const Stats = require("../package/contents/ui/cards/stats.js");

assert.ok(Stats.query().indexOf("totalCommitContributions") !== -1, "query asks commits");
assert.ok(Stats.query().indexOf("stargazerCount") !== -1, "query asks stars");

const data = { viewer: {
    contributionsCollection: { totalCommitContributions: 1851 },
    pullRequests: { totalCount: 89 },
    issues: { totalCount: 23 },
    repositories: { nodes: [ { stargazerCount: 100 }, { stargazerCount: 34 }, { stargazerCount: 0 } ] }
} };
const m = Stats.parse(data);
assert.strictEqual(m.commits, 1851, "commits");
assert.strictEqual(m.prs, 89, "prs");
assert.strictEqual(m.issues, 23, "issues");
assert.strictEqual(m.stars, 134, "stars summed across repos");

const m2 = Stats.parse({ viewer: {
    contributionsCollection: { totalCommitContributions: 0 },
    pullRequests: { totalCount: 0 }, issues: { totalCount: 0 },
    repositories: { nodes: [] }
} });
assert.strictEqual(m2.stars, 0, "no repos → 0 stars");

console.log("ok - stats.js");
