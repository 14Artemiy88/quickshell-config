#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
source = (Path(sys.argv[1]) / "components/notifications/Notifications.qml").read_text(encoding="utf-8")
checks = {
    "each notification card owns a pointer hover handler": "HoverHandler {\n                        id: cardHoverHandler",
    "hover state is read from the handler": "readonly property bool pointerHovered: cardHoverHandler.hovered",
    "timeout pauses while hovered": "&& card.inViewport && !card.pointerHovered && card.effectiveTimeout > 0",
    "timeout still requires viewport visibility": "card.inViewport && !card.pointerHovered",
    "hover pause preserves the accumulated elapsed time": "property real visibleTimeoutElapsed: 0",
    "visible elapsed time advances from measured timestamps": "card.visibleTimeoutElapsed += tickElapsed",
    "the tick origin is reset when the timer pauses or resumes": "card.visibleTimeoutLastTick = running ? Date.now() : 0",
    "countdown and expiry share the normalized timeout": "NotificationTimeout.remainingFraction(visibleTimeoutElapsed, effectiveTimeout)",
    "indicator is absent for persistent notifications": "card.effectiveTimeout > 0",
}
for description, needle in checks.items():
    assert needle in source, f"{description}: missing {needle!r}"
assert source.count("visibleTimeoutElapsed = 0") == 1, "hovering must not reset the accumulated timeout"
assert "onHoveredChanged: card.visibleTimeoutElapsed = 0" not in source
print("notification hover pause and shared visible-time countdown: OK")
PY
