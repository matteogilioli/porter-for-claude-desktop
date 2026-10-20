#!/bin/zsh
# Packs dist/Porter for Claude Desktop.app into dist/Porter.dmg: a window with the app, a shortcut to
# Applications to drag it onto, and the background from assets/dmg. Uses dmgbuild (installed in a
# throwaway virtual environment when missing), which lays out the window without Finder.
set -euo pipefail
cd "$(dirname "$0")/.."

APP="dist/Porter for Claude Desktop.app"
DMGBUILD="$(command -v dmgbuild || true)"
if [[ -z "$DMGBUILD" ]]; then
  VENV="$(mktemp -d)/venv"
  python3 -m venv "$VENV"
  "$VENV/bin/pip" install --quiet dmgbuild
  DMGBUILD="$VENV/bin/dmgbuild"
fi
rm -f dist/Porter.dmg
"$DMGBUILD" -s scripts/dmg-settings.py -D app="$APP" -D background=assets/dmg/background.tiff \
  "Porter for Claude Desktop" dist/Porter.dmg
echo "Built dist/Porter.dmg"
