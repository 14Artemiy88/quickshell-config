#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OPTIONS="$ROOT/components/TimerOptions.qml"
python3 - "$OPTIONS" <<'PYCODE'
from pathlib import Path
import sys
source = Path(sys.argv[1]).read_text(encoding="utf-8")
assert 'Scale {' not in source and 'popupCollapseScale' not in source
assert 'Translate {' in source and 'id: popupTranslation' in source
assert 'clip: true' in source and 'id: slideClip' in source
assert 'slideXAnimation' in source and 'slideYAnimation' in source
assert 'slideOffsetX = targetSlideX' in source
assert 'slideOffsetY = targetSlideY' in source
assert 'popupContentVisible = false' in source
assert 'slideXAnimation.duration = slideX ? duration : 0' in source
assert 'slideYAnimation.duration = slideY ? duration : 0' in source
print('Timer options now uses clipped directional translation rather than scale-collapse: OK')
PYCODE
