# GitHub Profile Cards

A KDE Plasma 6 widget that keeps my GitHub activity on the desktop: contribution
graph, language breakdown, profile, and a few stats. I got tired of opening the
browser just to glance at my graph, so I put it in a panel.

You pick which of the cards to show and in what order.

The idea — turning your GitHub activity into a set of cards — comes from
[lowlighter/metrics](https://github.com/lowlighter/metrics), which renders the same kind
of thing as an image for your profile README. I wanted a live version on my desktop
instead.

## Features

- **Contribution heatmap**, scoped to the last week, month, or year
- **Languages** breakdown across your repositories, drawn as a proportional bar
- **Profile**: avatar, name, bio, followers/following/repos, company, location, and how
  long you've been on GitHub — every field can be hidden individually
- **Stats**: stars, commits this year, pull requests, issues, sponsors, sponsoring,
  gists, and organizations, each with its GitHub icon
- Turn cards on/off and reorder them from the settings
- One or more columns; the widget resizes itself to fit what's shown
- Refreshes on a timer (and there's a manual refresh button)

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
*GitHub Profile Cards*.

After pulling updates, run `./scripts/install.sh` again and restart the shell:

```bash
kquitapp6 plasmashell && kstart plasmashell
```

## Uninstall

```bash
kpackagetool6 -t Plasma/Applet -r id.alnyz.githubgraph
rm -f ~/.local/share/icons/hicolor/256x256/apps/id.alnyz.githubgraph.png \
      ~/.local/share/icons/breeze/status/22/id.alnyz.githubgraph-mark.svg
```

## Configuration

Right-click the widget and pick **Configure**.

- **General** — refresh interval and number of columns.
- **Cards** — enable or disable each card, reorder with the up/down buttons, and set
  each card's own options (profile fields, language count, heatmap range, colors).

The Languages and Contributions cards always take the full width. Profile and Stats
are the ones that flow into the columns you set.

## How it uses your account

It only reads. The widget asks `gh` for its existing token and sends read-only GraphQL
queries straight to GitHub's API for your own profile and contribution data. Nothing is
written to your account, and nothing is sent anywhere other than GitHub.

## Known limitations

- The star total and the language breakdown are summed over your first 100 owned
  repositories. If you have more than that, both will be a slight undercount.
- It shows the account `gh` is signed in as — there's no setting to point it at a
  different GitHub user.

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

[ARCHITECTURE.md](ARCHITECTURE.md) explains how the whole thing fits together, and
[CONTRIBUTING.md](CONTRIBUTING.md) walks through the dev loop and adding a card
step by step.

Issues and pull requests are welcome.

## Credits

- The stat icons are [GitHub Octicons](https://github.com/primer/octicons) (MIT),
  bundled under `package/contents/icons/stats/`.
- The avatar uses [Kirigami Addons](https://invent.kde.org/libraries/kirigami-addons).

## License

MIT
