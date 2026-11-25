#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ROW="$ROOT/components/mopidy/MopidyQueueTrackRow.qml"
MAIN="$ROOT/components/mopidy/Mopidy.qml"

# The formatted title (and therefore the separator) is used only after the artist
# row has fully collapsed into the explicit one-line display mode.
grep -Fq 'readonly property bool oneLineModeSettled: Config.mopidyTrackArtistDisplayMode === "one-line"' "$ROW"
grep -Fq '&& artistLineMorph.normalizedProgress <= 0.001' "$ROW"
grep -Fq 'return trackTextArea.oneLineModeSettled' "$ROW"
grep -Fq '? controller.formatOneLineTrack(artistName, trackName)' "$ROW"
grep -Fq ': trackName' "$ROW"
grep -Fq 'textFormat: trackTextArea.oneLineModeSettled ? Text.StyledText : Text.PlainText' "$ROW"
grep -Fq 'Config.mopidyTrackArtistSeparator' "$MAIN"
# Keep the separator out of the two-line Text path.
node - "$ROW" <<'JS'
const fs = require('fs');
const s = fs.readFileSync(process.argv[2], 'utf8');
const start = s.indexOf('text: {');
const end = s.indexOf('\n                }', start);
if (start < 0 || end < 0) throw new Error('track title text binding not found');
const block = s.slice(start, end);
if (!block.includes('? controller.formatOneLineTrack(artistName, trackName)')) throw new Error('one-line mode does not use formatted separator text');
if (!block.includes(': trackName')) throw new Error('two-line mode must use plain track title');
console.log('Mopidy one-line-only artist separator: OK');
JS
printf 'Mopidy artist separator mode regression: OK\n'
