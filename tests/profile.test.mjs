import assert from "node:assert";
import { createRequire } from "node:module";
const require = createRequire(import.meta.url);
const Profile = require("../package/contents/ui/cards/profile.js");

assert.ok(Profile.query().indexOf("avatarUrl") !== -1, "query asks for avatarUrl");
assert.ok(Profile.query().indexOf("followers { totalCount }") !== -1, "query asks for followers count");
assert.ok(Profile.query().indexOf("createdAt") !== -1, "query asks for createdAt");
assert.ok(Profile.query().indexOf("location") !== -1, "query asks for location");
assert.ok(Profile.query().indexOf("company") !== -1, "query asks for company");

const data = { viewer: {
    name: "Ali", login: "Alnyz", avatarUrl: "https://x/y.png", bio: "hi",
    company: "AsyncLine", location: "Jakarta",
    createdAt: "2017-04-20T17:22:53Z",
    followers: { totalCount: 42 }, following: { totalCount: 18 },
    repositories: { totalCount: 27 }
} };
const m = Profile.parse(data);
assert.strictEqual(m.name, "Ali");
assert.strictEqual(m.login, "Alnyz");
assert.strictEqual(m.avatarUrl, "https://x/y.png");
assert.strictEqual(m.bio, "hi");
assert.strictEqual(m.company, "AsyncLine");
assert.strictEqual(m.location, "Jakarta");
assert.strictEqual(m.joined, "2017-04-20T17:22:53Z");
assert.strictEqual(m.followers, 42);
assert.strictEqual(m.following, 18);
assert.strictEqual(m.repos, 27);

const m2 = Profile.parse({ viewer: {
    name: null, login: "Alnyz", avatarUrl: "u", bio: null,
    company: null, location: null, createdAt: null,
    followers: { totalCount: 0 }, following: { totalCount: 0 }, repositories: { totalCount: 0 }
} });
assert.strictEqual(m2.name, "Alnyz", "name falls back to login");
assert.strictEqual(m2.bio, "", "bio falls back to empty string");
assert.strictEqual(m2.company, "", "company falls back to empty string");
assert.strictEqual(m2.location, "", "location falls back to empty string");
assert.strictEqual(m2.joined, "", "joined falls back to empty string");

console.log("ok - profile.js");
