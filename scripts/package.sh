#!/usr/bin/env bash
# Build a distributable .plasmoid (a zip with metadata.json + contents/ at its root)
# for upload to store.kde.org. Output lands in dist/.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PKG="$ROOT/package"
DIST="$ROOT/dist"
BASE="github-profile-cards"

# Version comes from the package metadata so the archive name always matches.
VERSION="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["KPlugin"]["Version"])' "$PKG/metadata.json")"
OUT="$DIST/$BASE-$VERSION.plasmoid"

mkdir -p "$DIST"
rm -f "$OUT"

# Prefer the zip CLI; fall back to python3 where it isn't installed. Either way the
# archive root is metadata.json + contents/ (NOT the package/ dir), as KDE expects.
if command -v zip >/dev/null 2>&1; then
    ( cd "$PKG" && zip -rq "$OUT" metadata.json contents -x '*/.*' '.*' )
else
    python3 - "$PKG" "$OUT" <<'PY'
import os, sys, zipfile
src, out = sys.argv[1], sys.argv[2]
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
    for root, dirs, files in os.walk(src):
        dirs[:] = [d for d in dirs if not d.startswith(".")]
        for f in files:
            if f.startswith("."):
                continue
            full = os.path.join(root, f)
            z.write(full, os.path.relpath(full, src))
PY
fi

echo "Built $OUT"
echo "Upload this file at store.kde.org (Plasma 6 Add-Ons -> Plasma Widgets)."
