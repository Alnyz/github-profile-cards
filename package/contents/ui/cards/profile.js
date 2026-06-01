// profile.js — Profile card data module. Plain JS (QML import + Node require).
function query() {
    return "query { viewer { name login avatarUrl bio followers { totalCount } following { totalCount } repositories(ownerAffiliations: OWNER) { totalCount } } }";
}

function parse(data) {
    var v = data.viewer;
    return {
        name: v.name || v.login,
        login: v.login,
        avatarUrl: v.avatarUrl,
        bio: v.bio || "",
        followers: v.followers.totalCount,
        following: v.following.totalCount,
        repos: v.repositories.totalCount
    };
}

if (typeof module !== "undefined" && module.exports) {
    module.exports = { query: query, parse: parse };
}
