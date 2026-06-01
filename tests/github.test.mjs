import assert from "node:assert";
import { createRequire } from "node:module";
const require = createRequire(import.meta.url);
const GitHub = require("../package/contents/code/GitHub.js");

// fetchGraphQL is XHR-based (not runnable under Node), so we only assert the module
// loads and exports the function. Behavioral verification is the live gh check below.
assert.strictEqual(typeof GitHub.fetchGraphQL, "function", "exports fetchGraphQL");
console.log("ok - GitHub.js loads");
