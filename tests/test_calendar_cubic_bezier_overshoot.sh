#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
morph = (root / "components/primitives/MorphGeometry.qml").read_text(encoding="utf-8")
calendar = (root / "components/CalendarWidget.qml").read_text(encoding="utf-8")
curves = (root / "js/AnimationCurves.js").read_text(encoding="utf-8")
config = (root / "Config.qml").read_text(encoding="utf-8")

# Qt requires both the BezierSpline easing type and its point list.
assert 'easing.type: root.animationEasing' in morph
assert 'easing.bezierCurve: root.animationBezierCurve' in morph
assert 'return Easing.BezierSpline' in config
assert 'return [custom[0], custom[1], custom[2], custom[3], 1, 1]' in curves

# Keep raw eased output for overshoot geometry; keep alpha/visibility normalized.
assert 'readonly property real animatedProgress:' in morph
assert 'Math.max(0, Math.min(1, animatedProgress))' in morph
assert 'fromGeometry.width) * animatedProgress)' in morph
assert 'fromGeometry.height) * animatedProgress)' in morph

# Calendar note overlay must use the selected calendar profile and raw progress
# for a visible scale overshoot (not the clamped normalized value).
assert 'animationProfile: Config.animationCalendarMorphProfile' in calendar
assert 'animationEasing: Config.animationEasingType(Config.animationCalendarMorphProfile, root.noteOverlayMode !== "" ? "enter" : "exit")' in calendar
assert 'animationBezierCurve: Config.animationBezierCurve(Config.animationCalendarMorphProfile, root.noteOverlayMode !== "" ? "enter" : "exit")' in calendar
assert 'scale: 0.90 + 0.10 * noteOverlayMorph.animatedProgress' in calendar
assert 'opacity: root.noteOverlayOpacityProgress' in calendar
assert 'visible: root.noteOverlayMode !== "" || root.noteOverlayOpacityProgress > 0.001' in calendar
assert 'Behavior on noteOverlayOpacityProgress' in calendar
assert 'easing.type: Easing.Linear' in calendar

# The exact user-provided CSS curve really has Y overshoot above the endpoint.
x1, y1, x2, y2 = 0.34, 1.56, 0.64, 1.0
def cubic(a, b, c, d, t):
    u = 1.0 - t
    return u*u*u*a + 3*u*u*t*b + 3*u*t*t*c + t*t*t*d
peak = 0.0
for step in range(1, 1000):
    x_target = step / 1000.0
    lo, hi = 0.0, 1.0
    for _ in range(32):
        mid = (lo + hi) / 2.0
        if cubic(0.0, x1, x2, 1.0, mid) < x_target:
            lo = mid
        else:
            hi = mid
    peak = max(peak, cubic(0.0, y1, y2, 1.0, (lo + hi) / 2.0))
assert peak > 1.05, f"example cubic-bezier should overshoot visibly; sampled peak was {peak}"
print(f"Calendar CSS cubic-bezier is wired to Easing.BezierSpline and preserves overshoot (peak {peak:.3f}): OK")
PY
