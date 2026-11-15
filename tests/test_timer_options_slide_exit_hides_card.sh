#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OPTIONS="$ROOT/components/TimerOptions.qml"
python3 - "$OPTIONS" <<'PYCODE'
from pathlib import Path
import sys
source = Path(sys.argv[1]).read_text(encoding="utf-8")
assert 'property bool popupContentVisible: false' in source
assert 'visible: popupContentVisible' in source
show = source.split('onSelectedFileChanged: {', 1)[1].split('onTimersChanged:', 1)[0]
assert 'slideOffsetX = slideTargetX(true, style)' in show
assert 'slideOffsetY = slideTargetY(true, style)' in show
assert 'popupContentVisible = true' in show
finish = source.split('function finishCloseOnce()', 1)[1].split('function startClose()', 1)[0]
assert 'if (!closing || closeSignalSent) return' in finish
assert 'popupContentVisible = false' in finish
assert finish.index('popupContentVisible = false') < finish.index('closeFinished()')
transition = source.split('ParallelAnimation {\n        id: visualTransition', 1)[1].split('\n    }', 1)[0]
assert 'onFinished: root.finishCloseOnce()' in transition
assert 'slideXAnimation.to = targetSlideX' in source
assert 'slideYAnimation.to = targetSlideY' in source
assert 'slideOffsetX = targetSlideX' in source and 'slideOffsetY = targetSlideY' in source
print('Timer options stays mapped during clipped slide exit and hides after transition completion: OK')
PYCODE
