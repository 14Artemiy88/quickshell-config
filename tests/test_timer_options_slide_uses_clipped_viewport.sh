#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OPTIONS="$ROOT/components/TimerOptions.qml"
python3 - "$OPTIONS" <<'PYCODE'
from pathlib import Path
import sys
source = Path(sys.argv[1]).read_text(encoding="utf-8")
assert 'id: slideClip' in source and 'anchors.fill: parent' in source and 'clip: true' in source
assert 'id: slideContent' in source and 'width: root.width' in source and 'height: root.height' in source
assert 'transform: Translate {' in source and 'id: popupTranslation' in source
assert 'x: root.slideOffsetX' in source and 'y: root.slideOffsetY' in source
for child in ['Rectangle', 'MouseArea', 'Column']:
    assert f'{child} {{\n        parent: slideContent' in source, f'{child} must move inside the clipped content viewport'
assert source.count('parent: slideContent') >= 7, 'background, frame, hit area, editors and action content must share the slide transform'
assert 'target: root\n            property: "x"' not in source and 'target: root\n            property: "y"' not in source
assert 'popupCollapseScale' not in source
print('Timer options slide is clipped to its fixed viewport; card and controls translate together: OK')
PYCODE
