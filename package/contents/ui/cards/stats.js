// stats.js — Stats card data module. Plain JS (QML import + Node require).
function query() {
    return "query { viewer { contributionsCollection { totalCommitContributions } pullRequests { totalCount } issues { totalCount } repositories(ownerAffiliations: OWNER, first: 100) { nodes { stargazerCount } } } }";
}

function parse(data) {
    var v = data.viewer;
    var stars = 0;
    var nodes = (v.repositories && v.repositories.nodes) || [];
    for (var i = 0; i < nodes.length; i++) {
        stars += nodes[i].stargazerCount;
    }
    return {
        stars: stars,
        commits: v.contributionsCollection.totalCommitContributions,
        prs: v.pullRequests.totalCount,
        issues: v.issues.totalCount
    };
}

if (typeof module !== "undefined" && module.exports) {
    module.exports = { query: query, parse: parse };
}
