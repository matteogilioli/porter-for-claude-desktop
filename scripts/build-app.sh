#!/bin/zsh
# Builds "Porter for Claude Desktop.app" into ./dist (pass --install to copy it to ~/Applications).
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${VERSION:-0.1.0}"
# A tag gives "1.0.0"; a branch or pull request ("main", "12/merge") is not a version.
[[ "$VERSION" =~ ^[0-9]+(\.[0-9]+)*$ ]] || VERSION=0.1.0
APP="dist/Porter for Claude Desktop.app"

swift build -c release --arch arm64 --arch x86_64
BIN="$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)/Porter"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$APP/Contents/Frameworks"
cp "$BIN" "$APP/Contents/MacOS/Porter"
# The updater; -R keeps its symlinks, which its code signature covers.
cp -R "$(dirname "$BIN")/Sparkle.framework" "$APP/Contents/Frameworks/"
ICONSET="$(mktemp -d)/AppIcon.iconset"
"$BIN" --write-iconset "$ICONSET"
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"
cat > "$APP/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>Porter</string>
  <key>CFBundleDisplayName</key><string>Porter for Claude Desktop</string>
  <key>CFBundleIdentifier</key><string>io.github.matteogilioli.porter</string>
  <key>CFBundleExecutable</key><string>Porter</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>CFBundleLocalizations</key>
  <array><string>en</string><string>zh-Hans</string><string>es</string><string>fr</string><string>de</string>
    <string>pt-BR</string><string>ja</string><string>ko</string><string>it</string><string>ru</string></array>
  <key>CFBundleShortVersionString</key><string>${VERSION}</string>
  <key>CFBundleVersion</key><string>${VERSION}</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><true/>
  <key>CFBundleURLTypes</key>
  <array><dict><key>CFBundleURLName</key><string>Claude links</string>
    <key>CFBundleURLSchemes</key><array><string>claude</string></array></dict></array>
  <key>SUFeedURL</key><string>https://github.com/matteogilioli/porter-for-claude-desktop/releases/latest/download/appcast.xml</string>
  <key>SUPublicEDKey</key><string>ix+zqSlkITXuV5fslQDG+/wU8/y+tDuJMBemA7Gwkew=</string>
  <key>SUEnableAutomaticChecks</key><true/>
  <key>NSAppleEventsUsageDescription</key><string>Porter passes Claude links to the Claude profile you used last.</string>
  <key>NSHumanReadableCopyright</key><string>MIT License</string>
</dict></plist>
EOF
codesign --force --sign - "$APP"
echo "Built $APP"

if [[ "${1:-}" == "--install" ]]; then
  mkdir -p ~/Applications
  # A running copy would keep running the old code (opening the new one only brings it to the front).
  pkill -x Porter && sleep 1 || true
  rm -rf ~/Applications/"Porter for Claude Desktop.app"
  cp -R "$APP" ~/Applications/
  echo "Installed to ~/Applications/Porter for Claude Desktop.app"
  open ~/Applications/"Porter for Claude Desktop.app"
fi
