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

if [ "${1:-}" = "--reload" ]; then
    kquitapp6 plasmashell || true
    sleep 1
    (plasmashell >/dev/null 2>&1 &)
    echo "plasmashell reloaded"
fi
