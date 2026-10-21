#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT/components/primitives/AnimatedVisibility.qml" "$ROOT/shell.qml" <<'PY'
from pathlib import Path
import sys

qml = Path(sys.argv[1]).read_text(encoding="utf-8")
shell = Path(sys.argv[2]).read_text(encoding="utf-8")

# Entry and exit must animate the same transform. Animating the anchored
# exitHost instead of contentTransform made slide-out inconsistent with slide-in.
show = qml.split('id: showTransition', 1)[1].split('id: hideTransition', 1)[0]
hide = qml.split('id: hideTransition', 1)[1].split('onShownChanged:', 1)[0]
assert 'target: contentTransform' in show and 'property: "x"' in show and 'property: "y"' in show
assert 'target: contentTransform' in hide and 'property: "x"' in hide and 'property: "y"' in hide
assert 'target: exitHost' not in hide, "slide-out must not animate an anchored wrapper"

# A zero-duration opacity animation to 0 made slide-out vanish immediately.
assert 'to: root.usesOpacity() ? 0 : 1' in hide
assert 'duration: root.usesOpacity() ? root.activeDuration : 0' in hide
assert 'contentHost.opacity = root.usesOpacity() ? 0 : 1' in hide
assert 'contentTransform.x = root.hiddenX()' in hide
assert 'contentTransform.y = root.hiddenY()' in hide

# Window-level owners must keep their layer-shell surface alive for the whole
# hide transition; otherwise the compositor destroys the animation mid-flight.
for marker, expected in (
    ('id: calendarWindow', 'visible: Settings.calendar && (shell.calendarVisible || calendarVisibility.running || shell.layoutEditMode)'),
    ('id: mopidyWindow', 'visible: Settings.mopidy && (!Config.mopidyToggleWithPlayerRightClick || shell.mopidyVisible || mopidyVisibility.running || shell.layoutEditMode)'),
    ('id: settingsWindow', 'visible: shell.settingsVisible || settingsVisibility.running'),
):
    start = shell.index(marker)
    # Bound each assertion to a reasonable component-sized region.
    chunk = shell[start:start + 2500]
    assert expected in chunk, f"window must remain visible during its transition: {marker}"

print("AnimatedVisibility slide-out transition: OK")
PY
