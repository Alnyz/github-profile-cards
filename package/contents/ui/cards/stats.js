// Stats card: GraphQL query and response parser.
function query() {
    return "query { viewer { contributionsCollection { totalCommitContributions } pullRequests { totalCount } issues { totalCount } sponsors { totalCount } sponsoring { totalCount } gists { totalCount } organizations { totalCount } repositories(ownerAffiliations: OWNER, first: 100) { nodes { stargazerCount } } } }";
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
        issues: v.issues.totalCount,
        sponsors: v.sponsors.totalCount,
        sponsoring: v.sponsoring.totalCount,
        gists: v.gists.totalCount,
        orgs: v.organizations.totalCount
    };
}

if (typeof module !== "undefined" && module.exports) {
    module.exports = { query: query, parse: parse };
}
