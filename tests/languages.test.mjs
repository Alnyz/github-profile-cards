import assert from "node:assert";
import { createRequire } from "node:module";
const require = createRequire(import.meta.url);
const Lang = require("../package/contents/ui/cards/languages.js");

assert.ok(Lang.query(false).indexOf("isFork: false") !== -1, "excludes forks by default");
assert.ok(Lang.query(true).indexOf("isFork") === -1, "includes forks when asked");

const data = { viewer: { repositories: { nodes: [
    { languages: { edges: [
        { size: 300, node: { name: "Python", color: "#3572A5" } },
        { size: 100, node: { name: "Shell", color: "#89e051" } }
    ] } },
    { languages: { edges: [
        { size: 200, node: { name: "Python", color: "#3572A5" } },
        { size: 400, node: { name: "Go", color: "#00ADD8" } }
    ] } }
] } } };
const m = Lang.parse(data, 2);
assert.strictEqual(m.total, 1000, "grand total bytes");
assert.strictEqual(m.langs.length, 2, "topN=2 slices to 2");
assert.strictEqual(m.langs[0].name, "Python", "Python first (500)");
assert.strictEqual(m.langs[0].size, 500, "Python aggregated across repos");
assert.strictEqual(m.langs[1].name, "Go", "Go second (400)");
assert.ok(Math.abs(m.langs[0].pct - 50) < 0.001, "Python 50%");
assert.ok(Math.abs(m.langs[1].pct - 40) < 0.001, "Go 40%");

const m2 = Lang.parse({ viewer: { repositories: { nodes: [] } } }, 5);
assert.strictEqual(m2.total, 0);
assert.strictEqual(m2.langs.length, 0);

console.log("ok - languages.js");
