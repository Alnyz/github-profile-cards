# Changelog

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project follows
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] — 2026-06-04

### Added
- **Stars card** — your most recently starred repositories, each with its language,
  license, and star/fork/issue/PR counts. Click a row to open the repo. Off by default.
- **Achievements card** — rank medals (Master/Super/Great, modeled on lowlighter/metrics)
  worked out from your GitHub stats. 15 achievements, each ranked S/A/B/C against fixed
  thresholds, with two display modes — a medallion grid or a detailed list — selectable in
  the settings. Off by default.

### Changed
- The widget's height is now user-resizable. It still auto-grows to fit and never lets you
  drag it small enough to clip a card, so after disabling cards you can drag the bottom edge
  up to reclaim the empty space. (Plasma's desktop containment can't auto-shrink a placed
  widget; the previous fixed size left it stuck.)
- Updated the README, ARCHITECTURE, and CONTRIBUTING docs to cover the new cards and the
  sizing behaviour.

## [0.1.0] — 2026-06-02

### Added
- Initial release.
- Cards: **Profile**, **Stats**, **Languages**, and **Contributions** (the contribution
  heatmap).
- Enable, disable, and reorder cards from the settings; lay them out in one or more columns.
- Reads your account through the GitHub CLI (`gh`); read-only GraphQL queries, no token entry.
- Refreshes on a timer, with a manual refresh button.

[0.2.0]: https://github.com/Alnyz/github-profile-cards/releases/tag/v0.2.0
[0.1.0]: https://github.com/Alnyz/github-profile-cards/releases/tag/v0.1.0
