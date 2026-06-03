// Achievements card: GraphQL query + table-driven S/A/B/C rank computation.
// Synthesized ranks (à la lowlighter/metrics), NOT GitHub's native badges.

// One query on viewer. Every field is verified to succeed under the default gh token
// scopes (gist, read:org, repo, workflow) — do NOT add scope-gated fields (packages,
// projects, deployments): fetchGraphQL aborts the whole card on any errors entry.
function query() {
    return "query { viewer { "
        + "repositories(first: 100, ownerAffiliations: OWNER, isFork: false) { totalCount nodes { forkCount primaryLanguage { name } } } "
        + "forks: repositories(privacy: PUBLIC, isFork: true) { totalCount } "
        + "pullRequests { totalCount } "
        + "contributionsCollection { pullRequestReviewContributions { totalCount } } "
        + "gists { totalCount } "
        + "organizations { totalCount } "
        + "starredRepositories { totalCount } "
        + "followers { totalCount } "
        + "following { totalCount } "
        + "createdAt "
        + "sponsorshipsAsSponsor { totalCount } "
        + "discussionsStarted: repositoryDiscussions { totalCount } "
        + "discussionsComments: repositoryDiscussionComments { totalCount } "
        + "popular: repositories(first: 1, orderBy: {field: STARGAZERS, direction: DESC}) { nodes { stargazerCount } } "
        + "} }";
}

// Thousands grouping: 1247 -> "1,247". Regex avoids Qt's inconsistent toLocaleString.
function groupNum(n) {
    return String(n).replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

// plural(1,"star") -> "star"; plural(2,"star") -> "stars".
// plural(1,"repositor","y","ies") -> "repository"; plural(3,...) -> "repositories".
function plural(n, base, one, many) {
    one = one === undefined ? "" : one;
    many = many === undefined ? "s" : many;
    return base + (n === 1 ? one : many);
}

// Rank x against thresholds [c,b,a,s,m]. X = locked (kept, shown greyed by the view).
// progress may exceed 1 for values above the S cap (t[4]); the view clamps it for the gauge arc.
function rank(x, t) {
    if (x >= t[3]) return { rank: "S", progress: (x - t[3]) / (t[4] - t[3]) };
    if (x >= t[2]) return { rank: "A", progress: (x - t[2]) / (t[3] - t[2]) };
    if (x >= t[1]) return { rank: "B", progress: (x - t[1]) / (t[2] - t[1]) };
    if (x >= t[0]) return { rank: "C", progress: (x - t[0]) / (t[1] - t[0]) };
    return { rank: "X", progress: t[0] > 0 ? x / t[0] : 0 };
}

// Per-rank presentation. Colors from metrics' classic template (title/gauge per rank;
// glyph = [#primary, #secondary] recolor pair used by medals.medalSvg). X = locked (grey).
var RANK_TITLE = { S: "#EB355E", A: "#D79533", B: "#9D8FFF", C: "#58A6FF", X: "#666666" };
var RANK_GAUGE = { S: "#EB355E", A: "#E7BD69", B: "#9E91FF", C: "#58A6FF", X: "#B0B0B0" };
var RANK_GLYPH = { S: ["#EB355E", "#731237"], A: ["#B59151", "#FFD576"], B: ["#7D6CFF", "#B2A8FF"], C: ["#2088FF", "#79B8FF"], X: ["#7A7A7A", "#B0B0B0"] };
var RANK_PREFIX = { S: "Master", A: "Super", B: "Great", C: "", X: "" };
var RANK_ORDER = { S: 4, A: 3, B: 2, C: 1, X: 0 };

// Declarative achievement table. value per id is precomputed in parse(); the medal glyph
// is looked up by id in medals.js.
var DEFS = [
    { id: "developer", title: "Developer", thresholds: [1, 20, 50, 100, 250],
      desc: function(n) { return "Published " + groupNum(n) + " public " + plural(n, "repositor", "y", "ies"); } },
    { id: "maintainer", title: "Maintainer", thresholds: [1, 1000, 5000, 10000, 25000],
      desc: function(n) { return "Maintaining a repository with " + groupNum(n) + " " + plural(n, "star"); } },
    { id: "influencer", title: "Influencer", thresholds: [1, 200, 500, 1000, 2500],
      desc: function(n) { return "Followed by " + groupNum(n) + " " + plural(n, "user"); } },
    { id: "polyglot", title: "Polyglot", thresholds: [1, 4, 8, 16, 32],
      desc: function(n) { return "Using " + groupNum(n) + " different programming " + plural(n, "language"); } },
    { id: "member", title: "Member", thresholds: [1, 3, 5, 10, 15],
      desc: function(n) { return "Registered " + groupNum(n) + " " + plural(n, "year") + " ago"; } },
    { id: "stargazer", title: "Stargazer", thresholds: [1, 200, 500, 1000, 2500],
      desc: function(n) { return "Starred " + groupNum(n) + " " + plural(n, "repositor", "y", "ies"); } },
    { id: "contributor", title: "Contributor", thresholds: [1, 200, 500, 1000, 2500],
      desc: function(n) { return "Opened " + groupNum(n) + " pull " + plural(n, "request"); } },
    { id: "reviewer", title: "Reviewer", thresholds: [1, 200, 500, 1000, 2500],
      desc: function(n) { return "Reviewed " + groupNum(n) + " pull " + plural(n, "request"); } },
    { id: "gister", title: "Gister", thresholds: [1, 20, 50, 100, 250],
      desc: function(n) { return "Published " + groupNum(n) + " " + plural(n, "gist"); } },
    { id: "worker", title: "Worker", thresholds: [1, 2, 4, 8, 10],
      desc: function(n) { return "Joined " + groupNum(n) + " " + plural(n, "organization"); } },
    { id: "follower", title: "Follower", thresholds: [1, 200, 500, 1000, 2500],
      desc: function(n) { return "Following " + groupNum(n) + " " + plural(n, "user"); } },
    { id: "sponsor", title: "Sponsor", thresholds: [1, 3, 5, 10, 25],
      desc: function(n) { return "Sponsoring " + groupNum(n) + " " + plural(n, "user") + " or " + plural(n, "organization"); } },
    { id: "forker", title: "Forker", thresholds: [1, 5, 10, 20, 50],
      desc: function(n) { return "Forked " + groupNum(n) + " public " + plural(n, "repositor", "y", "ies"); } },
    { id: "inspirer", title: "Inspirer", thresholds: [1, 100, 500, 1000, 2500],
      desc: function(n) { return "A repository forked " + groupNum(n) + " " + plural(n, "time"); } },
    { id: "chatter", title: "Chatter", thresholds: [1, 200, 500, 1000, 2500],
      desc: function(n) { return "Participated in discussions " + groupNum(n) + " " + plural(n, "time"); } }
];

// Build the view model. `now` (epoch ms) is injected so the Member age calc is testable.
function parse(data, now) {
    var v = data.viewer || {};
    function tc(obj) { return (obj && obj.totalCount) || 0; }

    var repoNodes = (v.repositories && v.repositories.nodes) || [];
    var maxForks = 0;
    var langSet = {};
    for (var i = 0; i < repoNodes.length; i++) {
        var fc = repoNodes[i].forkCount || 0;
        if (fc > maxForks) maxForks = fc;
        var pl = repoNodes[i].primaryLanguage;
        if (pl && pl.name) langSet[pl.name] = true;
    }
    var langCount = 0;
    for (var key in langSet) { if (langSet.hasOwnProperty(key)) langCount++; }

    var popular = (v.popular && v.popular.nodes && v.popular.nodes[0]) || null;
    var ageYears = v.createdAt ? (now - Date.parse(v.createdAt)) / (365.25 * 24 * 3600 * 1000) : 0;

    var cc = v.contributionsCollection;
    var values = {
        developer: tc(v.repositories),
        maintainer: popular ? (popular.stargazerCount || 0) : 0,
        influencer: tc(v.followers),
        polyglot: langCount,
        member: ageYears,
        stargazer: tc(v.starredRepositories),
        contributor: tc(v.pullRequests),
        reviewer: cc ? tc(cc.pullRequestReviewContributions) : 0,
        gister: tc(v.gists),
        worker: tc(v.organizations),
        follower: tc(v.following),
        sponsor: tc(v.sponsorshipsAsSponsor),
        forker: tc(v.forks),
        inspirer: maxForks,
        chatter: tc(v.discussionsStarted) + tc(v.discussionsComments)
    };

    var out = [];
    for (var d = 0; d < DEFS.length; d++) {
        var def = DEFS[d];
        var val = values[def.id];
        var r = rank(val, def.thresholds);
        // Member is a float (years); display its floor. Locked (X) achievements are kept
        // and shown greyed, like the metrics medal grid.
        var displayVal = def.id === "member" ? Math.floor(val) : val;
        out.push({
            id: def.id,
            title: def.title,
            prefix: RANK_PREFIX[r.rank],
            description: def.desc(displayVal),
            rank: r.rank,
            locked: r.rank === "X",
            value: displayVal,
            progress: r.progress < 0 ? 0 : (r.progress > 1 ? 1 : r.progress),
            titleColor: RANK_TITLE[r.rank],
            gaugeColor: RANK_GAUGE[r.rank],
            glyphPrimary: RANK_GLYPH[r.rank][0],
            glyphSecondary: RANK_GLYPH[r.rank][1]
        });
    }
    out.sort(function(a, b) {
        return (RANK_ORDER[b.rank] + b.progress * 0.99) - (RANK_ORDER[a.rank] + a.progress * 0.99);
    });
    return { achievements: out };
}

if (typeof module !== "undefined" && module.exports) {
    module.exports = { query: query, parse: parse, rank: rank, groupNum: groupNum, plural: plural };
}
