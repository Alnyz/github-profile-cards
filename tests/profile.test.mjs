import assert from "node:assert";
import { createRequire } from "node:module";
const require = createRequire(import.meta.url);
const Profile = require("../package/contents/ui/cards/profile.js");

assert.ok(Profile.query().indexOf("avatarUrl") !== -1, "query asks for avatarUrl");
assert.ok(Profile.query().indexOf("followers { totalCount }") !== -1, "query asks for followers count");

const data = { viewer: {
    name: "Ali", login: "Alnyz", avatarUrl: "https://x/y.png", bio: "hi",
    followers: { totalCount: 42 }, following: { totalCount: 18 },
    repositories: { totalCount: 27 }
} };
const m = Profile.parse(data);
assert.strictEqual(m.name, "Ali");
assert.strictEqual(m.login, "Alnyz");
assert.strictEqual(m.avatarUrl, "https://x/y.png");
assert.strictEqual(m.bio, "hi");
assert.strictEqual(m.followers, 42);
assert.strictEqual(m.following, 18);
assert.strictEqual(m.repos, 27);

const m2 = Profile.parse({ viewer: {
    name: null, login: "Alnyz", avatarUrl: "u", bio: null,
    followers: { totalCount: 0 }, following: { totalCount: 0 }, repositories: { totalCount: 0 }
} });
assert.strictEqual(m2.name, "Alnyz", "name falls back to login");
assert.strictEqual(m2.bio, "", "bio falls back to empty string");

console.log("ok - profile.js");
