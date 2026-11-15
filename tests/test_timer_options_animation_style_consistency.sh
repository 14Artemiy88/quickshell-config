#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OPTIONS="$ROOT/components/TimerOptions.qml"
python3 - "$OPTIONS" <<'PYCODE'
from pathlib import Path
import sys
source = Path(sys.argv[1]).read_text(encoding="utf-8")
assert 'function slideXEnabled(style)' in source
assert 'style === "slideLeft" || style === "slideRight"' in source
assert 'function slideYEnabled(style)' in source
assert 'style === "slideUp" || style === "slideDown"' in source
assert 'function slideTargetX(hidden, style)' in source
assert 'function slideTargetY(hidden, style)' in source
assert 'if (style === "slideLeft") return -root.width' in source
assert 'if (style === "slideRight") return root.width' in source
assert 'if (style === "slideUp") return -root.height' in source
assert 'if (style === "slideDown") return root.height' in source
assert 'slideXAnimation.duration = slideX ? duration : 0' in source
assert 'slideYAnimation.duration = slideY ? duration : 0' in source
assert 'showOpacityAnimation.duration = fadeEnabled ? duration : 0' in source
assert 'popupCollapseScale' not in source
assert 'if (!closing && selectedFile === "" && !popupHasBeenShown)' in source
selection = source.split('onSelectedFileChanged: {', 1)[1].split('onTimersChanged:', 1)[0]
assert 'slideOffsetX = slideTargetX(true, style)' in selection
assert 'slideOffsetY = slideTargetY(true, style)' in selection
none_branch = source.split('function syncVisualState()', 1)[1].split('var baseDuration', 1)[0]
assert 'if (!animationsActive())' in none_branch
assert 'slideOffsetX = targetSlideX' in none_branch
assert 'slideOffsetY = targetSlideY' in none_branch
print('Timer options styles share one transition and respect direction/duration: OK')
PYCODE
