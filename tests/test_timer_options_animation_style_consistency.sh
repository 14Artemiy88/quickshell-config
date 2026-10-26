#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OPTIONS="$ROOT/components/TimerOptions.qml"
python3 - "$OPTIONS" <<'PYCODE'
from pathlib import Path
import sys
source = Path(sys.argv[1]).read_text(encoding="utf-8")
assert 'function slideOffsetX(style)' in source
assert 'if (style === "slideLeft") return -root.width' in source
assert 'if (style === "slideRight") return root.width' in source
assert 'function slideOffsetY(style)' in source
assert 'if (style === "slideUp") return -root.height' in source
assert 'if (style === "slideDown") return root.height' in source
assert 'target: popupTranslation' in source
assert 'property: "x"' in source and 'property: "y"' in source
assert 'showXAnimation.duration = slideXEnabled ? duration : 0' in source
assert 'showYAnimation.duration = slideYEnabled ? duration : 0' in source
assert 'showOpacityAnimation.duration = fadeEnabled ? duration : 0' in source
assert 'if (!closing && selectedFile === "" && !popupHasBeenShown)' in source, 'startup hidden state must be distinguished from a real close after the popup was shown'
none_branch = source.split('function syncVisualState()', 1)[1].split('var baseDuration', 1)[0]
assert 'if (!animationsActive())' in none_branch
assert 'popupTranslation.x = targetX' in none_branch and 'popupTranslation.y = targetY' in none_branch
print('Timer options popup honors fade/slide direction and immediate none state: OK')
PYCODE
