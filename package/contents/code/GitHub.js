// Shared GraphQL transport for GitHub's API. Usable from QML and Node.

// Sends a query to GitHub. Calls onOk(data) with the response's `data` on success,
// or onErr(message) on failure. Exactly one of the two is called.
function fetchGraphQL(token, query, variables, onOk, onErr) {
    var xhr = new XMLHttpRequest();
    xhr.open("POST", "https://api.github.com/graphql");
    xhr.setRequestHeader("Authorization", "bearer " + token);
    xhr.setRequestHeader("Content-Type", "application/json");
    xhr.onreadystatechange = function() {
        if (xhr.readyState !== XMLHttpRequest.DONE) {
            return;
        }
        if (xhr.status === 0) {
            onErr("Network error contacting GitHub");
            return;
        }
        var data;
        try {
            var resp = JSON.parse(xhr.responseText);
            if (xhr.status === 401) {
                onErr("Token rejected (401) — re-authenticate");
                return;
            }
            if (resp.errors && resp.errors.length) {
                onErr(resp.errors[0].message || "GitHub API error");
                return;
            }
            data = resp.data;
        } catch (e) {
            onErr(e.message || ("HTTP " + xhr.status));
            return;
        }
        // Outside the try so a throwing callback isn't mistaken for a transport error.
        onOk(data);
    };
    xhr.send(JSON.stringify({ query: query, variables: variables || {} }));
}

if (typeof module !== "undefined" && module.exports) {
    module.exports = { fetchGraphQL: fetchGraphQL };
}
