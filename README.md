# GitHub Cards

A KDE Plasma 6 widget that keeps my GitHub activity on the desktop: contribution
graph, language breakdown, profile, and a few stats. I got tired of opening the
browser just to glance at my graph, so I put it in a panel.

You pick which of the cards to show and in what order.

## Features

- Contribution heatmap, scoped to the last week, month, or year
- Language breakdown across your repositories, drawn as a proportional bar
- Profile card: avatar, name, bio, and follower/following/repo counts (you can hide
  any of these fields)
- Stats: total stars, commits this year, pull requests, and issues
- Turn cards on/off and reorder them from the settings
- One or more columns; the widget resizes itself to fit what's shown

## Requirements

- KDE Plasma 6
- [GitHub CLI](https://cli.github.com/) (`gh`), signed in. The widget reads your
  account through it, so set that up first:
  ```bash
  # Arch / CachyOS
  sudo pacman -S github-cli
  gh auth login
  ```
- `kirigami-addons` for the avatar (it's already installed on most KDE systems)

## Installation

```bash
git clone https://github.com/Alnyz/github-graph-widget.git
cd github-graph-widget
./scripts/install.sh
```

Then right-click the desktop or a panel, open **Add Widgets…**, and look for
*GitHub Contribution Graph*.

After pulling updates, run `./scripts/install.sh` again and restart the shell:

```bash
kquitapp6 plasmashell && kstart plasmashell
```

## Configuration

Right-click the widget and pick **Configure**.

- **General** — refresh interval and number of columns.
- **Cards** — enable or disable each card, reorder with the up/down buttons, and set
  each card's own options (profile fields, language count, heatmap range, colors).

The Languages and Contributions cards always take the full width. Profile and Stats
are the ones that flow into the columns you set.

## Development

Each card's query and response parsing live in a plain `.js` file with no Qt
dependency, so they run under Node:

```bash
for t in tests/*.test.mjs; do node "$t"; done
```

For the QML, `qmllint` catches most mistakes (the `Unqualified access` warnings about
`plasmoid` are expected and fine):

```bash
/usr/lib/qt6/bin/qmllint package/contents/ui/main.qml
```

How the package is laid out:

```
package/contents/
  code/GitHub.js           shared GraphQL request helper
  ui/cards/<name>.js        a card's query + parser  (tested under tests/)
  ui/cards/<Name>Card.qml   a card's view; fetches its own data
  ui/CardHost.qml           arranges the enabled cards into rows and columns
  ui/main.qml               reads the gh token and hosts the cards
  config/, ui/Config*.qml   settings schema and pages
```

To add a card: write its `<name>.js` (query + parser) and a `<Name>Card.qml` matching
the same properties as the existing cards, register it in `ui/ConfigCards.qml`, and add
any new keys to `config/main.xml`.

## License

MIT
