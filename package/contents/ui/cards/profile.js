// Profile card: GraphQL query and response parser.
function query() {
    return "query { viewer { name login avatarUrl bio company location createdAt followers { totalCount } following { totalCount } repositories(ownerAffiliations: OWNER) { totalCount } } }";
}

function parse(data) {
    var v = data.viewer;
    return {
        name: v.name || v.login,
        login: v.login,
        avatarUrl: v.avatarUrl,
        bio: v.bio || "",
        company: v.company || "",
        location: v.location || "",
        joined: v.createdAt || "",
        followers: v.followers.totalCount,
        following: v.following.totalCount,
        repos: v.repositories.totalCount
    };
}

if (typeof module !== "undefined" && module.exports) {
    module.exports = { query: query, parse: parse };
}
