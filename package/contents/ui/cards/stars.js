// Stars card: GraphQL query and response parser for recently starred repos.
function query(limit) {
    var n = Math.max(1, limit === undefined ? 3 : limit);
    return "query { viewer { starredRepositories(first: " + n
        + ", orderBy: {field: STARRED_AT, direction: DESC}) { edges { starredAt node { "
        + "url nameWithOwner description stargazerCount forkCount "
        + "primaryLanguage { name color } licenseInfo { nickname spdxId } "
        + "issues(states: OPEN) { totalCount } pullRequests(states: OPEN) { totalCount } "
        + "} } } } }";
}

// Format a count GitHub-style: 999 -> "999", 7420 -> "7.42k", 23000 -> "23k", 1.5e6 -> "1.5m".
// toFixed can round e.g. 999999/1000 up to "1000"; promote to the next unit when it does.
function compact(n) {
    if (!n) return "0";
    if (n < 1000) return String(n);
    if (n < 1000000) {
        var k = (n / 1000).toFixed(2).replace(/\.?0+$/, "");
        if (k !== "1000") return k + "k";
    }
    return (n / 1000000).toFixed(2).replace(/\.?0+$/, "") + "m";
}

// Relative time from an ISO date to `now` (epoch ms): hours (<1 day), then exact days
// (<30 days), then a coarse week count beyond 30 days (so the first week label is "4 weeks
// ago" — intentional: stars older than a month only need an approximate age).
function relTime(iso, now) {
    var days = (now - new Date(iso).getTime()) / (24 * 60 * 60 * 1000);
    var out;
    if (days < 1) {
        var h = Math.max(1, Math.ceil(days * 24));
        out = h + " hour" + (h >= 2 ? "s" : "") + " ago";
    } else if (days < 30) {
        var d = Math.floor(days);
        out = d + " day" + (d >= 2 ? "s" : "") + " ago";
    } else {
        var w = Math.floor(days / 7);
        out = w + " week" + (w >= 2 ? "s" : "") + " ago";
    }
    return "starred " + out;
}

// Build the view model. `now` (epoch ms) is injected so relative times are testable.
function parse(data, now) {
    var sr = data.viewer && data.viewer.starredRepositories;
    var edges = (sr && sr.edges) || [];
    var repos = [];
    for (var i = 0; i < edges.length; i++) {
        var e = edges[i];
        var node = e.node || {};
        var lang = node.primaryLanguage;
        var lic = node.licenseInfo;
        var stars = node.stargazerCount || 0;
        var forks = node.forkCount || 0;
        var issues = (node.issues && node.issues.totalCount) || 0;
        var prs = (node.pullRequests && node.pullRequests.totalCount) || 0;
        repos.push({
            url: node.url || "",
            name: node.nameWithOwner || "",
            description: node.description || "",
            stars: stars, starsText: compact(stars),
            forks: forks, forksText: compact(forks),
            issues: issues, issuesText: compact(issues),
            prs: prs, prsText: compact(prs),
            language: lang ? lang.name : null,
            languageColor: lang ? (lang.color || "#888888") : null,
            license: lic ? (lic.nickname || lic.spdxId || null) : null,
            starred: relTime(e.starredAt, now)
        });
    }
    return { repos: repos };
}

if (typeof module !== "undefined" && module.exports) {
    module.exports = { query: query, parse: parse, compact: compact, relTime: relTime };
}
