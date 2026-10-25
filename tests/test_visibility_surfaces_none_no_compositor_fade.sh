#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
widget = (root / "components/WidgetWindow.qml").read_text(encoding="utf-8")
visibility = (root / "components/primitives/AnimatedVisibility.qml").read_text(encoding="utf-8")
shell = (root / "shell.qml").read_text(encoding="utf-8")

# A stable layer-shell surface prevents compositor-level open/close animations
# from replacing the selected per-module style (especially `none`). It must be
# click-through and blur-free when the animated content is not visible.
assert "property bool manageInputMask: false" in widget
assert "property bool inputMaskEnabled: true" in widget
assert "mask: root.manageInputMask ? managedInputMask : null" in widget
assert "item: root.inputMaskEnabled ? contentHost : null" in widget
assert "width: 0" in widget and "height: 0" in widget
assert "property Item backgroundBlurItem: contentHost" in widget
assert "property bool backgroundBlurVisible: true" in widget
assert "root.backgroundBlurEnabled && root.backgroundBlurVisible ? root.backgroundBlurItem : null" in widget

# Blur follows the same item that physically moves during slide-in/out; a
# Translate-only visual transform leaves the compositor region stationary.
assert "readonly property Item blurRegionItem: contentHost" in visibility
assert "contentTransform" not in visibility
assert 'target: contentHost' in visibility
assert 'property: "x"' in visibility and 'property: "y"' in visibility

# The runtime here has no QuickShell/QML parser, so still reject delimiter
# mistakes in every touched QML file before relying on the structural checks.
pairs = {')': '(', ']': '[', '}': '{'}
for name in ("components/WidgetWindow.qml", "components/primitives/AnimatedVisibility.qml", "shell.qml"):
    source = (root / name).read_text(encoding="utf-8")
    stack = []
    state = "code"
    i = 0
    while i < len(source):
        c = source[i]
        n = source[i + 1] if i + 1 < len(source) else ""
        if c == "\n":
            if state == "line_comment": state = "code"
            i += 1
            continue
        if state == "line_comment":
            i += 1
            continue
        if state == "block_comment":
            if c == "*" and n == "/": state = "code"; i += 2
            else: i += 1
            continue
        if state in ("single", "double", "template"):
            quote = {"single": "'", "double": '"', "template": '`'}[state]
            if c == "\\": i += 2; continue
            if c == quote: state = "code"
            i += 1
            continue
        if c == "/" and n == "/": state = "line_comment"; i += 2; continue
        if c == "/" and n == "*": state = "block_comment"; i += 2; continue
        if c == "'": state = "single"
        elif c == '"': state = "double"
        elif c == '`': state = "template"
        elif c in "([{": stack.append(c)
        elif c in ")]}":
            assert stack and stack[-1] == pairs[c], f"{name}: mismatched delimiter {c}"
            stack.pop()
        i += 1
    assert not stack and state not in ("single", "double", "template", "block_comment"), f"{name}: unclosed delimiter or literal"

expected_windows = (
    ("id: calendarWindow", "visible: Settings.calendar", "backgroundBlurItem: calendarVisibility.blurRegionItem", "inputMaskEnabled: shell.calendarVisible || calendarVisibility.running || shell.layoutEditMode"),
    ("id: mopidyWindow", "visible: Settings.mopidy", "backgroundBlurItem: mopidyVisibility.blurRegionItem", "inputMaskEnabled: !Config.mopidyToggleWithPlayerRightClick || shell.mopidyVisible || mopidyVisibility.running || shell.layoutEditMode"),
    ("id: settingsWindow", "visible: true", "backgroundBlurItem: settingsVisibility.blurRegionItem", "inputMaskEnabled: shell.settingsVisible || settingsVisibility.running"),
)
for marker, visible, blur_item, mask in expected_windows:
    start = shell.index(marker)
    block = shell[start:start + 3200]
    assert visible in block, f"surface lifetime should not follow content visibility: {marker}"
    assert "manageInputMask: true" in block, f"hidden surface must be click-through: {marker}"
    assert mask in block, f"input mask must track only visible content: {marker}"
    assert blur_item in block, f"blur region must track animated content: {marker}"
    assert "backgroundBlurVisible:" in block, f"blur region must be cleared when content is hidden: {marker}"

print("Stable surfaces avoid compositor fade; hidden input masks clear and blur follows slide geometry: OK")
PY
