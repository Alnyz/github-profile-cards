// GitHub.js — shared GraphQL transport. Plain JS module (QML import + Node require).
// Do NOT add `.pragma library` (QML-only; breaks Node tests).

// POST a GraphQL query to GitHub. On success calls onOk(data) where `data` is the
// response's `data` object (transport + GraphQL errors already handled here).
// On any failure calls onErr(messageString). Exactly one of onOk/onErr fires.
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
        // onOk OUTSIDE the try so a throw from a card's parser/UI is not miscaught
        // and surfaced as a transport error (which would fire both callbacks).
        onOk(data);
    };
    xhr.send(JSON.stringify({ query: query, variables: variables || {} }));
}

if (typeof module !== "undefined" && module.exports) {
    module.exports = { fetchGraphQL: fetchGraphQL };
}
