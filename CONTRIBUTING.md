# Contributing

Thanks for taking a look. This is a small project and I'm happy to take fixes,
new cards, and improvements. This guide covers how to get set up, how I work on
it day to day, and exactly what touching each part involves. For *why* things are
shaped the way they are, read [ARCHITECTURE.md](ARCHITECTURE.md) first — it'll make
the steps below make sense.

## What you'll need

- **KDE Plasma 6** (I develop on 6.6, Wayland). You need a running Plasma session to
  see your changes.
- **`gh` CLI**, signed in (`gh auth login`). The widget reads your GitHub account
  through it, so without it there's nothing to render.
- **Node** — to run the parser tests. No npm packages required; the tests use Node's
  built-in `assert`.
- **`qmllint`** for QML — it ships with Qt 6 (`/usr/lib/qt6/bin/qmllint`, often via the
  `qt6-declarative` / `plasma-sdk` packages).

## Getting the code running

```bash
git clone https://github.com/Alnyz/github-profile-cards.git
cd github-profile-cards
./scripts/install.sh
```

`install.sh` installs the plasmoid into your user directory and copies the icons into
your icon theme. Add the widget from **Add Widgets…** and you're looking at your own
build.

## The day-to-day loop

I keep this loop tight:

1. Edit a file.
2. `./scripts/install.sh` — reinstalls the package.
3. Reload Plasma so it picks up the change:
   ```bash
   kquitapp6 plasmashell; sleep 1; (plasmashell >/dev/null 2>&1 &)
   ```
   Then re-open the widget (existing instances refresh; if you changed defaults or the
   config schema, remove and re-add the widget to pick them up).
4. For anything with logic, run the tests and lint (below) before reloading — they
   catch most mistakes without a Plasma round-trip.

A note on debugging: if a card or page renders **blank**, it's almost always a QML load
error. The journal is often empty (a detached `plasmashell` throws its errors away), so
don't trust that — run `qmllint` on the file, which will point at the real problem.

## Tests and lint

Run the parser tests (they're plain Node, no setup):

```bash
for t in tests/*.test.mjs; do node "$t"; done
```

Lint a QML file:

```bash
/usr/lib/qt6/bin/qmllint package/contents/ui/main.qml
```

Ignore the `Unqualified access` warnings about `plasmoid` — they're expected (the
`plasmoid` context object isn't visible to the linter). What matters is anything that
says `... was not found`, a type error, or a syntax error.

Before you send a change: **parser tests pass, and the QML you touched lints clean.**

## Adding a card

This is the most common kind of contribution, and the framework is built to make it
self-contained. A card is two files plus a one-line registration. As a worked example,
here's a minimal "Followers" card that shows your follower count.

### 1. The data module — `package/contents/ui/cards/followers.js`

Pure functions, no Qt, so it can be tested under Node. `query()` returns a GraphQL
string; `parse(data)` turns the response's `data` into a model object.

```js
// Followers card: GraphQL query and response parser.
function query() {
    return "query { viewer { followers { totalCount } } }";
}

function parse(data) {
    return { count: data.viewer.followers.totalCount };
}

if (typeof module !== "undefined" && module.exports) {
    module.exports = { query: query, parse: parse };
}
```

Keep these in plain ES5-style JavaScript (`var`, `function`) — the same file runs in
both QML's JS engine and Node, and I keep it conservative so it works in both. Don't
add `.pragma library`; it's QML-only and breaks the Node tests.

### 2. The test — `tests/followers.test.mjs`

Every parser gets a test. Mirror the existing ones:

```js
import assert from "node:assert";
import { createRequire } from "node:module";
const require = createRequire(import.meta.url);
const Followers = require("../package/contents/ui/cards/followers.js");

assert.ok(Followers.query().indexOf("followers { totalCount }") !== -1, "query asks followers");

const m = Followers.parse({ viewer: { followers: { totalCount: 76 } } });
assert.strictEqual(m.count, 76);

console.log("ok - followers.js");
```

```bash
node tests/followers.test.mjs   # expect: ok - followers.js
```

### 3. The view — `package/contents/ui/cards/FollowersCard.qml`

The filename is the capitalised id + `Card.qml` (the host derives it from the id). Match
the card contract exactly — `token`, `cardId`, `fullWidth`, `model`, `status`,
`reload()` — and follow the standard fetch lifecycle:

```qml
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../../code/GitHub.js" as GitHub
import "followers.js" as Followers

// Followers card: shows the viewer's follower count.
ColumnLayout {
    id: card

    property string token: ""
    readonly property string cardId: "followers"
    readonly property bool fullWidth: false
    property var model: null
    property string status: ""

    Layout.fillWidth: true
    spacing: Kirigami.Units.smallSpacing

    function reload() {
        if (card.token.length === 0) return;
        card.status = "loading";
        GitHub.fetchGraphQL(card.token, Followers.query(), {},
            function(data) { card.model = Followers.parse(data); card.status = ""; },
            function(msg)  { card.status = msg; });
    }

    onTokenChanged: reload()
    Component.onCompleted: if (card.token.length > 0) reload()

    PlasmaComponents.Label {
        text: "FOLLOWERS"
        font: Kirigami.Theme.smallFont
        opacity: 0.5
    }
    PlasmaComponents.Label {
        visible: card.model !== null
        font.bold: true
        text: card.model ? (card.model.count + " followers") : ""
    }
    PlasmaComponents.Label {
        visible: card.status !== "" && card.status !== "loading"
        color: Kirigami.Theme.negativeTextColor
        text: card.status
    }

    // The row divider is drawn by CardHost.
}
```

### 4. Register it — `package/contents/ui/ConfigCards.qml`

Add one entry to the `registry` array so the card shows up in the settings list. The
`id` must match the card's `cardId` and map to the file (`followers` → `FollowersCard.qml`):

```qml
readonly property var registry: [
    { id: "profile",   label: "Profile" },
    { id: "stats",     label: "Stats" },
    { id: "languages", label: "Languages" },
    { id: "heatmap",   label: "Contribution heatmap" },
    { id: "followers", label: "Followers" }        // ← new
]
```

That's the minimum. Enable it in the widget's settings (or add `followers` to the
`cards` default in `config/main.xml` if you want it on by default), reinstall, reload,
and it renders.

### If your card needs settings

1. Declare the keys in `config/main.xml` (with sensible defaults).
2. Read them in the card via `plasmoid.configuration.<key>`. If a setting changes
   *what* you fetch, add a `Connections { target: plasmoid.configuration; function
   on<Key>Changed() { card.reload(); } }`. If it only changes *how* the data looks, bind
   to it directly and don't reload.
3. Add a per-card options section to `ConfigCards.qml`: a block shown via
   `visible: page.isEnabled("followers")`, with a `cfg_<key>` alias for each control. (An
   alias can target any id in the page except one inside the enable/reorder `Repeater` —
   see ARCHITECTURE.md. Keep the section inside the page's `SimpleKCM` content layout so it
   scrolls with the rest.)

### If your card should span the full width

Cards default to flowing into the configured columns. To make one always span every
column (like the heatmap, languages, stars, and achievements cards): set `fullWidth: true`
on the card **and** add its id to `CardHost.isFullWidth(id)`. Both need to list it — the
host groups cards into rows before they're instantiated, so it can't read the property on
its own.

### Keep ids single lowercase words

The host turns an id into a filename by upper-casing the first letter
(`followers` → `FollowersCard.qml`). Stick to single lowercase words so that mapping is
unambiguous.

## Adding a setting (no new card)

- Declare the key in `config/main.xml`.
- Add the control to `ConfigGeneral.qml` (a `cfg_<key>` alias) or to the relevant card's
  options in `ConfigCards.qml`.
- Read it where it's used via `plasmoid.configuration.<key>`.

## Code conventions

- **Card data modules** (`cards/*.js`): plain ES5 JS, no Qt, no `.pragma library`,
  pure `query()`/`parse()`, and the Node `module.exports` guard at the bottom.
- **Keep the data layer and the view separate.** Anything testable should live in the
  `.js` so it can be covered without Plasma.
- **Match the existing style** in the file you're editing — small, focused QML files,
  comments only where the *why* isn't obvious.
- **One concern per change.** Smaller PRs are easier for me to review and get in.

## Submitting changes

1. Make sure the parser tests pass and the QML you touched lints clean.
2. Test it in a real Plasma session — install, reload, look at it.
3. Open a pull request describing what changed and how you verified it. A screenshot
   helps a lot for anything visual.

If you're not sure about an idea, open an issue first and we can talk it through before
you write code. Bug reports are welcome too — include your Plasma version and what the
widget showed (or didn't).
