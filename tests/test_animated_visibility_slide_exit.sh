#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT/components/primitives/AnimatedVisibility.qml" "$ROOT/shell.qml" <<'PY'
from pathlib import Path
import sys

qml = Path(sys.argv[1]).read_text(encoding="utf-8")
shell = Path(sys.argv[2]).read_text(encoding="utf-8")

# Animate the content item's actual geometry, not only a visual transform: the
# compositor blur Region must follow the same x/y changes during slide transitions.
show = qml.split('id: showTransition', 1)[1].split('id: hideTransition', 1)[0]
hide = qml.split('id: hideTransition', 1)[1].split('onShownChanged:', 1)[0]
assert 'target: contentHost' in show and 'property: "x"' in show and 'property: "y"' in show
assert 'target: contentHost' in hide and 'property: "x"' in hide and 'property: "y"' in hide
assert 'readonly property Item blurRegionItem: contentHost' in qml
assert 'contentTransform' not in qml, "blur region must follow real geometry, not a Translate-only transform"

# A zero-duration opacity animation to 0 made slide-out vanish immediately.
assert 'to: root.usesOpacity() ? 0 : 1' in hide
assert 'duration: root.usesOpacity() ? root.activeDuration : 0' in hide
assert 'contentHost.opacity = root.usesOpacity() ? 0 : 1' in hide
assert 'contentHost.x = root.hiddenX()' in hide
assert 'contentHost.y = root.hiddenY()' in hide

# Keep a transparent surface alive so the compositor cannot inject its own
# open/close fade when a module style is `none`; click masks empty while hidden.
for marker, expected in (
    ('id: calendarWindow', 'visible: Settings.calendar'),
    ('id: mopidyWindow', 'visible: Settings.mopidy'),
    ('id: settingsWindow', 'visible: true'),
):
    start = shell.index(marker)
    chunk = shell[start:start + 3000]
    assert expected in chunk, f"surface lifetime must not follow content visibility: {marker}"
    assert 'manageInputMask: true' in chunk, f"hidden surface must become click-through: {marker}"
    assert 'backgroundBlurItem:' in chunk, f"blur must follow the animated content item: {marker}"

print("AnimatedVisibility slide-out, compositor surface lifetime, and blur geometry: OK")
PY
