#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FILE="$ROOT/components/notifications/Notifications.qml"
python3 - "$FILE" <<'PYCODE'
from pathlib import Path
import sys
source = Path(sys.argv[1]).read_text(encoding="utf-8")
assert "function notificationImageLooksLikeLeadingIcon(width, height)" in source
assert "notificationImageProbe.implicitWidth, notificationImageProbe.implicitHeight" in source
assert "notificationImageProbe.status === Image.Ready" in source
assert "source: card.imageSource" in source[source.index("id: notificationImageProbe") : source.index("property int progressValue", source.index("id: notificationImageProbe"))]
assert "|| imageDataLooksLikeLeadingIcon" in source
assert "&& !hasLeadingImage" in source
assert "source: card.hasLeadingImage ? card.imageSource : card.appIconSource" in source
print("notifications square image-data leading icon integration: OK")
PYCODE
node - "$FILE" <<'NODE'
const fs = require('fs');
const source = fs.readFileSync(process.argv[2], 'utf8');
const start = source.indexOf('function notificationImageLooksLikeLeadingIcon(width, height) {');
const end = source.indexOf('\n    function notificationLocalImagePath', start);
const fn = source.slice(start, end).replace('function notificationImageLooksLikeLeadingIcon', 'function notificationImageLooksLikeLeadingIcon');
const notificationImageLooksLikeLeadingIcon = new Function(`${fn}; return notificationImageLooksLikeLeadingIcon;`)();
for (const [w,h,expected,label] of [
  [48,48,true,'square 48px logo'],
  [128,120,true,'near-square project avatar'],
  [160,90,false,'landscape attachment'],
  [512,512,false,'large square photo'],
  [16,16,false,'tiny decorative image'],
  [96,48,false,'wide logo']
]) {
  const actual = notificationImageLooksLikeLeadingIcon(w,h);
  if (actual !== expected) throw new Error(`${label}: expected ${expected}, got ${actual}`);
}
console.log('notification image aspect/size classifier cases: 6/6 PASS');
NODE
