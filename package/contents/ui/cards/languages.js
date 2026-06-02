// Languages card: GraphQL query and response parser.
function query(includeForks) {
    var fork = includeForks ? "" : ", isFork: false";
    return "query { viewer { repositories(first: 100, ownerAffiliations: OWNER" + fork
        + ") { nodes { languages(first: 10, orderBy: {field: SIZE, direction: DESC}) { edges { size node { name color } } } } } } }";
}

// Aggregate language byte sizes across all repos, sort desc, take topN, add pct.
function parse(data, topN) {
    var nodes = (data.viewer.repositories && data.viewer.repositories.nodes) || [];
    var totals = {};
    var grand = 0;
    for (var i = 0; i < nodes.length; i++) {
        var edges = (nodes[i].languages && nodes[i].languages.edges) || [];
        for (var j = 0; j < edges.length; j++) {
            var e = edges[j];
            var name = e.node.name;
            if (!totals[name]) {
                totals[name] = { name: name, color: e.node.color || "#888888", size: 0 };
            }
            totals[name].size += e.size;
            grand += e.size;
        }
    }
    var arr = [];
    for (var k in totals) { arr.push(totals[k]); }
    arr.sort(function(a, b) { return b.size - a.size; });
    var top = arr.slice(0, topN || 5);
    for (var m = 0; m < top.length; m++) {
        top[m].pct = grand > 0 ? (top[m].size / grand * 100) : 0;
    }
    return { langs: top, total: grand };
}

if (typeof module !== "undefined" && module.exports) {
    module.exports = { query: query, parse: parse };
}
