#!/bin/zsh
# Writes dist/appcast.xml, the Sparkle feed for dist/Porter.dmg: one item for VERSION, signed with the
# EdDSA key in the file SPARKLE_KEY_FILE (default: the "porter" key in the login keychain), with the
# release notes from release-notes/VERSION.md. It goes on the GitHub release next to the disk image,
# where SUFeedURL finds the latest one.
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${VERSION:?set VERSION, e.g. 1.1.0}"
NOTES="release-notes/$VERSION.md"
[[ -f "$NOTES" ]] || { echo "Missing $NOTES" >&2; exit 1; }
REPO="https://github.com/matteogilioli/porter-for-claude-desktop"
# Comes with the Sparkle package, fetched by the build.
SIGN=".build/artifacts/sparkle/Sparkle/bin/sign_update"

if [[ -n "${SPARKLE_KEY_FILE:-}" ]]; then
  SIGNATURE="$("$SIGN" --ed-key-file "$SPARKLE_KEY_FILE" dist/Porter.dmg)"
else
  SIGNATURE="$("$SIGN" --account porter dist/Porter.dmg)"
fi

cat > dist/appcast.xml <<EOF
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>Porter for Claude Desktop</title>
    <item>
      <title>${VERSION}</title>
      <pubDate>$(LC_ALL=C date -u "+%a, %d %b %Y %H:%M:%S +0000")</pubDate>
      <sparkle:version>${VERSION}</sparkle:version>
      <sparkle:shortVersionString>${VERSION}</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
      <description sparkle:format="markdown"><![CDATA[
$(cat "$NOTES")
]]></description>
      <enclosure url="${REPO}/releases/download/v${VERSION}/Porter.dmg" type="application/octet-stream" ${SIGNATURE}/>
    </item>
  </channel>
</rss>
EOF
echo "Built dist/appcast.xml"
