#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT/components/Dashboard.qml" "$ROOT/js/dashboard/DashboardCards.js" <<'PY'
from pathlib import Path
import sys
qml = Path(sys.argv[1]).read_text()
cards = Path(sys.argv[2]).read_text()
assert 'anchors.margins: 18' in qml, 'Dashboard inner inset should retain its former value'
assert '            spacing: 14\n' in qml, 'header/actions/cards inner rhythm should retain its former value'
assert 'var COLUMN_GAP = 6' in cards, 'card-to-card gutter should stay compact'
assert 'ScrollBar.vertical:' not in qml, 'Visible Dashboard scrollbar remains attached'
assert 'WheelHandler {' in qml, 'Wheel/touchpad scrolling handler was removed'
assert 'cardsFlickable.contentY = Math.max(' in qml, 'Bounded wheel/touchpad scrolling is missing'
assert qml.count('Layout.alignment: Qt.AlignTop') >= 3, 'short compact peer and balanced columns must align to the top, not float in taller rows'
assert 'Math.max(horizontalBentoRowHeight,' not in qml, 'peer row height must not inherit the taller lead track'
print('Dashboard external spacing, natural compact alignment and hidden scrollbar: PASS')
PY
