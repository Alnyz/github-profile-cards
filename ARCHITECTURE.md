# Architecture

This is how the widget is put together. I wrote it for anyone who wants to fix
something, add a card, or just understand the moving parts. If you only want the
"how do I add a card" recipe, jump to [CONTRIBUTING.md](CONTRIBUTING.md) — this
document explains *why* things are shaped the way they are.

## The big picture

It's a KDE Plasma 6 plasmoid (a desktop/panel applet written in QML). The core idea
is a **card framework**: the widget itself is just a host that arranges a set of
self-contained "cards", and each card knows how to fetch and draw one thing
(profile, stats, languages, the contribution heatmap).

The data all comes from GitHub's GraphQL API. The token comes from the `gh` CLI that
the user already has signed in. There's no backend and no settings server — every
card talks to GitHub directly and renders the result.

```
gh auth token            DeviceToken.qml runs the gh CLI and hands back a token
      │
      ▼
main.qml                 holds the token, shows the auth prompt or the cards
      │
      ▼
CardHost.qml             groups the enabled cards into rows/columns
      │
      ▼
<Name>Card.qml           one per card; fetches its own data and renders it
      │  ├─ GitHub.fetchGraphQL(token, query)  →  GitHub GraphQL API
      │  └─ <name>.js parse(data)  →  model  →  bound into the view
      ▼
   pixels
```

## Package layout

A plasmoid is a directory that Plasma loads. `kpackagetool6` installs it to
`~/.local/share/plasma/plasmoids/id.alnyz.githubgraph/`.

```
package/
  metadata.json                 applet id, name, icon, category, API version
  contents/
    code/
      GitHub.js                 shared GraphQL request helper (fetchGraphQL)
    ui/
      main.qml                  root applet: token + host + sizing + auth prompt
      CompactRepresentation.qml panel form (just the GitHub mark)
      CardHost.qml              lays the enabled cards into rows/columns
      DeviceToken.qml           reads the gh token via the executable data engine
      HeatmapGrid.qml           the grid of contribution squares (pure view)
      ConfigGeneral.qml         settings page: refresh interval, columns
      ConfigCards.qml           settings page: enable/reorder + per-card options
      cards/
        <name>.js               a card's GraphQL query() + parse()  (no Qt; testable)
        <Name>Card.qml          a card's view; fetches its own data
    config/
      main.xml                  config schema (every persisted key)
      config.qml                registers the settings pages
    icons/
      icon.png                  app icon for the widget list
      github.svg                GitHub mark for the panel
      stats/                    Octicons used by the Stats card
```

Two layout rules worth calling out, because they're easy to trip on:

- **Config-page QML lives in `contents/ui/`, not `contents/config/`.** Plasma resolves
  a `ConfigCategory { source: "ConfigGeneral.qml" }` relative to `ui/`. Only `main.xml`
  and `config.qml` go in `config/`. If you put a page in `config/`, the settings dialog
  shows the category but renders a blank page.
- **`code/` is for plain JavaScript, `ui/` is for QML.** The card data modules
  (`cards/<name>.js`) deliberately have no Qt dependency so they run under plain Node
  for tests.

## How a Plasma widget hangs together here

A plasmoid has two "representations":

- **Compact** (`CompactRepresentation.qml`) — what shows in a panel: just the GitHub
  mark. Clicking it toggles `root.expanded`, which opens the full view in a popup.
- **Full** (`main.qml`'s `fullRepresentation`) — what shows on the desktop or in the
  popup: the cards.

Persisted settings live in `plasmoid.configuration`. Every key is declared in
`config/main.xml`; QML reads and writes them as `plasmoid.configuration.<key>`. The
settings dialog pages bind to those keys (see [Configuration](#configuration)).

## Authentication

The widget never asks for a password or token. `DeviceToken.qml` runs `gh auth token`
through Plasma's executable data engine (`org.kde.plasma.plasma5support`'s
`DataSource`), and emits the token string (or a failure message).

`main.qml` calls `deviceToken.request()` on startup. If it gets a token, the cards
render. If it fails (no `gh`, or not logged in), `main.qml` shows the "GitHub CLI
required" prompt instead of the cards. There is no OAuth path on purpose — a
device-flow "open this URL and type a code" UX doesn't fit a desktop widget.

## The shared transport: `code/GitHub.js`

One function does all the networking:

```js
fetchGraphQL(token, query, variables, onOk, onErr)
```

It POSTs the query to `https://api.github.com/graphql` with the token, then calls
**exactly one** of `onOk(data)` (with the response's `data` object) or
`onErr(message)`. It handles network failures, HTTP 401, and GraphQL `errors` so the
cards don't have to. `onOk` is intentionally called outside the `try/catch`, so an
exception thrown by a card's own parse/render code isn't misreported as a network
error.

`GitHub.js` is also written so Node can `require()` it (the `module.exports` guard at
the bottom), which is why it has no QML-only constructs.

## Cards

A card is the unit of the whole design. Each card is **two files** with one
responsibility each:

- `cards/<name>.js` — the **data**: a `query()` that returns a GraphQL string and a
  `parse(data)` that turns the response into a plain model object. Pure functions, no
  Qt, no side effects, so they're unit-tested under Node.
- `cards/<Name>Card.qml` — the **view**: fetches its own data via `fetchGraphQL`,
  keeps its own `model`/`status`, and renders.

### The card contract

`CardHost` and `main.qml` rely on every card exposing the same interface. A card is a
`ColumnLayout` with:

| Member | Type | Purpose |
|---|---|---|
| `token` | `string` | set by the host; the card fetches when it changes |
| `cardId` | `readonly string` | the card's id (matches its file/registry name) |
| `fullWidth` | `readonly bool` | whether it spans all columns (see the note below) |
| `model` | `var` | the parsed data, or `null` before the first fetch |
| `status` | `string` | `""`, `"loading"`, or an error message |
| `reload()` | function | (re)fetch and update `model`/`status` |

The lifecycle is always the same:

```qml
function reload() {
    if (card.token.length === 0) return;
    card.status = "loading";
    GitHub.fetchGraphQL(card.token, MyData.query(), {},
        function(data) { card.model = MyData.parse(data); card.status = ""; },
        function(msg)  { card.status = msg; });
}

onTokenChanged: reload()
Component.onCompleted: if (card.token.length > 0) reload()
```

If a card has settings that change *what* it fetches (the heatmap period, the language
count, the include-forks toggle), it also watches `plasmoid.configuration` and reloads:

```qml
Connections {
    target: plasmoid.configuration
    function onLanguagesCountChanged() { card.reload(); }
}
```

Settings that only change *how* the data is shown (the profile field toggles, the
heatmap colour) don't reload — the view just binds straight to the config key.

### `HeatmapGrid.qml`

The heatmap card delegates its actual grid to `HeatmapGrid.qml`, a pure view that takes
`weeks` (an array of week arrays of day objects) and draws coloured squares. It's the
only piece of view shared between cards, kept separate because it has real layout logic.

## `CardHost.qml`

The host turns the configured list of card ids into a laid-out set of cards.

- **Rows.** Full-width cards (heatmap, languages) each take their own row. The rest
  (profile, stats) pack into rows of `columnCount`. So at one column everything stacks;
  at two columns profile and stats sit side by side while the wide cards still span.
- **Dividers.** A single divider is drawn under each row by the host — that's why the
  cards themselves don't draw a divider. Side-by-side cards share one connected line.
- **Token.** Each card is instantiated through a `Loader`; on load the host binds the
  card's `token` to its own, so a token change (or re-auth) propagates to every card.
- **Refresh.** A `Timer` (interval = `refreshMinutes`) calls `reloadAll()`, which walks
  the nested row layouts and calls `reload()` on every loaded card. The manual Refresh
  button in `main.qml` calls the same thing.

**Full-width coupling (important).** Row grouping happens *before* the cards are
instantiated, so the host can't read a card's `fullWidth` property at grouping time.
Instead `CardHost.isFullWidth(id)` has a hardcoded list (`heatmap`, `languages`). If you
add a full-width card you must add its id there as well as setting `fullWidth: true` on
the card. The two need to agree.

## `main.qml`

The root applet. It:

- Acquires the token once (`DeviceToken`), exposes `token` and `authError`.
- Shows the auth/loading prompt while there's no token, the `CardHost` once there is.
- Hosts the manual Refresh button.
- Picks the compact representation for panels.

### Sizing

The widget sizes itself to its content and disables manual resizing (I'd rather it
always fit than have people fiddle with handles). It does that by pinning the layout's
min == preferred == max:

- **Width** comes from the heatmap's natural width — the configured period fixes the
  number of columns (week/month/year → 3/6/53), so the width is known before any data
  loads. `cell`/`gap` here must match the values in `HeatmapCard`.
- **Height** is bound to the layout's actual `implicitHeight`, so the box tracks the
  real rendered content and reacts when cards load or settings change.

This sizing is currently the one part that knows specifics about the heatmap card. If
the heatmap stops being the width-defining card, this is where you'd generalise it.

## Configuration

Three pieces:

- **`config/main.xml`** — the schema. Every persisted key, its type, and its default.
  Nothing is stored unless it's declared here.
- **`config/config.qml`** — registers the two settings pages (General, Cards).
- **`ui/ConfigGeneral.qml` / `ui/ConfigCards.qml`** — the page UIs.

### How a settings control binds to a key

Plasma's convention: a property named `cfg_<key>` on a config page's root is two-way
bound to the `<key>` entry in `main.xml`. For a simple control you alias it:

```qml
property alias cfg_refreshMinutes: refreshSpin.value
```

A `cfg_` alias can only point at an id that lives at the **page root scope** — not at
an id inside a `Repeater`/`Component` delegate (those ids aren't reachable, and the
page fails to load). That's why `ConfigCards` keeps the per-card option controls in
fixed sections at the root and only uses the `Repeater` for the enable/reorder rows
(which call page functions instead of aliasing ids).

### The Cards page

`ConfigCards.qml` does three things:

- **Enable / reorder.** `cfg_cards` is a `StringList` of the enabled card ids, in
  display order. The page renders a row per card (enabled cards first, then the rest)
  with a checkbox and up/down buttons. Toggling/moving rebuilds the array and reassigns
  it (a fresh array is what makes Plasma mark the page dirty and save).
- **The registry.** A small `registry` array of `{ id, label }` is the list of cards
  the page knows about. Add a card here and it appears in the list.
- **Per-card options.** Each card's options are a fixed section at the root, shown via
  `visible: page.isEnabled("<id>")`, with `cfg_` aliases for each control.

`ConfigGeneral.qml` is simpler: just the refresh interval and the column count.

## Icons

Three different icons, installed by `scripts/install.sh`:

- **Widget-list icon** — the dashboard `icons/icon.png`, copied into the hicolor icon
  theme under the applet's id, and referenced by `metadata.json`'s `Icon`.
- **Panel icon** — the monochrome GitHub mark `icons/github.svg`, copied into the breeze
  theme under a separate `-mark` name (so it recolours with the theme), referenced by
  `CompactRepresentation.qml`.
- **Stat icons** — GitHub Octicons in `icons/stats/`, shipped inside the package and
  drawn with `Kirigami.Icon { isMask: true; color: theme }` so they pick up the text
  colour. These don't need theme installation; they're loaded by path.

## Testing

- **Parsers** (`cards/<name>.js`) are pure, so they have real Node tests under
  `tests/`. This is where the logic-heavy bits (aggregation, fallbacks, field mapping)
  are covered.
- **QML** is checked with `qmllint`. The `Unqualified access` warnings about `plasmoid`
  are expected — every card has them.
- **Visual** behaviour is verified by installing and reloading Plasma and looking. A
  blank component with nothing in the journal usually means a QML load error;
  `qmllint` finds it (the journal can be empty because a detached `plasmashell`
  discards its stderr).

## Things that are deliberately coupled

So you're not surprised:

- `CardHost.isFullWidth(id)` and a card's `fullWidth` property must agree.
- `main.qml`'s width calc knows the heatmap's `cell`/`gap`; they must match
  `HeatmapCard`.
- A new card touches several files: its two source files, the `ConfigCards` registry
  (and option section if it has options), and `main.xml` for any new keys. See
  [CONTRIBUTING.md](CONTRIBUTING.md) for the exact checklist.
