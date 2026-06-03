import assert from "node:assert";
import { createRequire } from "node:module";
const require = createRequire(import.meta.url);
const Medals = require("../package/contents/ui/cards/medals.js");

// All 15 achievement glyphs are present.
const ids = ["developer","maintainer","influencer","polyglot","member","stargazer",
  "contributor","reviewer","gister","worker","follower","sponsor","forker","inspirer","chatter"];
for (const id of ids) {
  assert.ok(typeof Medals.GLYPHS[id] === "string" && Medals.GLYPHS[id].length > 0, "glyph for " + id);
}
assert.strictEqual(Object.keys(Medals.GLYPHS).length, 15, "exactly 15 glyphs");

// medalSvg() recolors #primary/#secondary and wraps in a 60x60 svg.
const svg = Medals.medalSvg("developer", "#7D6CFF", "#B2A8FF");
assert.ok(svg.indexOf('viewBox="0 0 60 60"') !== -1, "wrapped in 60x60 svg");
assert.ok(svg.indexOf("#primary") === -1 && svg.indexOf("#secondary") === -1, "placeholders replaced");
assert.ok(svg.indexOf("#7D6CFF") !== -1, "primary color substituted");
assert.ok(svg.indexOf("#B2A8FF") !== -1, "secondary color substituted");

// Unknown id -> empty (but well-formed) svg wrapper, no throw.
const empty = Medals.medalSvg("nope", "#000", "#111");
assert.ok(empty.indexOf("<svg") === 0 && empty.indexOf("</svg>") !== -1, "well-formed wrapper for unknown id");

console.log("ok - medals.js");
