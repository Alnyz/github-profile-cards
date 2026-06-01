import assert from "node:assert";
import { createRequire } from "node:module";
const require = createRequire(import.meta.url);
const Heatmap = require("../package/contents/ui/cards/heatmap.js");

const qYear = Heatmap.query(null, null);
assert.ok(qYear.indexOf("contributionsCollection {") !== -1, "year query has no args");
assert.ok(qYear.indexOf("contributionCalendar") !== -1, "year query asks for calendar");
const qRange = Heatmap.query("2025-01-01T00:00:00Z", "2025-01-08T00:00:00Z");
assert.ok(qRange.indexOf('from: "2025-01-01T00:00:00Z"') !== -1, "range query has from");
assert.ok(qRange.indexOf('to: "2025-01-08T00:00:00Z"') !== -1, "range query has to");

const data = {
    viewer: {
        contributionsCollection: {
            contributionCalendar: {
                totalContributions: 42,
                weeks: [
                    { contributionDays: [
                        { date: "2025-06-01", contributionCount: 0, color: "#ebedf0", weekday: 0 },
                        { date: "2025-06-02", contributionCount: 3, color: "#40c463", weekday: 1 }
                    ] },
                    { contributionDays: [
                        { date: "2025-06-08", contributionCount: 5, color: "#30a14e", weekday: 0 }
                    ] }
                ]
            }
        }
    }
};
const m = Heatmap.parse(data);
assert.strictEqual(m.total, 42, "total");
assert.strictEqual(m.days.length, 3, "flattened days");
assert.deepStrictEqual(m.days[0], { date: "2025-06-01", count: 0, color: "#ebedf0", weekday: 0 });
assert.strictEqual(m.weeks.length, 2, "weeks preserved");
assert.strictEqual(m.weeks[0].length, 2, "week 0 length");

console.log("ok - heatmap.js");
