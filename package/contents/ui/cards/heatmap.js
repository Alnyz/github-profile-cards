// heatmap.js — Heatmap card data module. Plain JS, usable from QML and Node.
// Do NOT add `.pragma library` (QML-only; breaks Node tests).

function query(fromISO, toISO) {
    var args = "";
    if (fromISO && toISO) {
        args = "(from: \"" + fromISO + "\", to: \"" + toISO + "\")";
    }
    return "query { viewer { contributionsCollection" + args
        + " { contributionCalendar { totalContributions weeks { contributionDays { date contributionCount color weekday } } } } } }";
}

function parse(data) {
    var cal = data.viewer.contributionsCollection.contributionCalendar;
    var weeks = [];
    var days = [];
    for (var w = 0; w < cal.weeks.length; w++) {
        var week = [];
        var raw = cal.weeks[w].contributionDays;
        for (var d = 0; d < raw.length; d++) {
            var day = {
                date: raw[d].date,
                count: raw[d].contributionCount,
                color: raw[d].color,
                weekday: raw[d].weekday
            };
            week.push(day);
            days.push(day);
        }
        weeks.push(week);
    }
    return { total: cal.totalContributions, days: days, weeks: weeks };
}

if (typeof module !== "undefined" && module.exports) {
    module.exports = { query: query, parse: parse };
}
