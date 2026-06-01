#!/usr/bin/env bash
# Install or update the plasmoid, then optionally reload plasmashell.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PKG="$ROOT/package"
ID="id.alnyz.githubgraph"
DEST="$HOME/.local/share/plasma/plasmoids/$ID"

if [ -d "$DEST" ]; then
    kpackagetool6 -t Plasma/Applet -u "$PKG"
else
    kpackagetool6 -t Plasma/Applet -i "$PKG"
fi

# Widget-list icon: the full-color dashboard app icon (hicolor), resolved by the
# applet's metadata Icon name.
ICON_DIR="$HOME/.local/share/icons/hicolor/256x256/apps"
mkdir -p "$ICON_DIR"
cp "$PKG/contents/icons/icon.png" "$ICON_DIR/$ID.png"
# Panel icon: the monochrome GitHub mark (breeze, recolors with the theme), under a
# separate "-mark" name so it doesn't override the dashboard icon.
MARK_DIR="$HOME/.local/share/icons/breeze/status/22"
mkdir -p "$MARK_DIR"
cp "$PKG/contents/icons/github.svg" "$MARK_DIR/$ID-mark.svg"
# Remove a stale same-name symbolic copy from older installs (would override the PNG).
rm -f "$MARK_DIR/$ID.svg"
kbuildsycoca6 >/dev/null 2>&1 || true

if [ "${1:-}" = "--reload" ]; then
    kquitapp6 plasmashell || true
    sleep 1
    (plasmashell >/dev/null 2>&1 &)
    echo "plasmashell reloaded"
fi
