#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OPTIONS="$ROOT/components/TimerOptions.qml"
python3 - "$OPTIONS" <<'PYCODE'
from pathlib import Path
import sys
source = Path(sys.argv[1]).read_text(encoding="utf-8")
assert 'Item {\n        id: slideClip' in source and 'clip: true' in source
assert 'Item {\n            id: slideContent' in source
assert 'transform: Translate {' in source and 'id: popupTranslation' in source
assert 'property real slideOffsetX: 0' in source and 'property real slideOffsetY: 0' in source
assert 'function slideTargetX(hidden, style)' in source
assert 'if (style === "slideLeft") return -root.width' in source
assert 'if (style === "slideRight") return root.width' in source
assert 'function slideTargetY(hidden, style)' in source
assert 'if (style === "slideUp") return -root.height' in source
assert 'if (style === "slideDown") return root.height' in source
assert 'slideXAnimation.to = targetSlideX' in source and 'slideYAnimation.to = targetSlideY' in source
assert 'slideXAnimation.duration = slideX ? duration : 0' in source
assert 'slideYAnimation.duration = slideY ? duration : 0' in source
assert 'parent: slideContent' in source
assert 'popupCollapseScale' not in source and 'xScale' not in source and 'yScale' not in source
print('Timer options use a true clipped translation from all four edges: OK')
PYCODE
