#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TAB="$ROOT/components/settings/primitives/SettingsTabBase.qml"
python3 - "$TAB" <<'PY'
from pathlib import Path
import sys
s = Path(sys.argv[1]).read_text(encoding='utf-8')
assert 'readonly property real visualBorderWidth:' in s
assert 'anchors.margins: root.selected ? root.visualBorderWidth : 0' in s
assert 'radius: Math.max(0, Config.scaledCornerRadius(root.cornerRadius) - (root.selected ? root.visualBorderWidth : 0))' in s
assert 'border.width: root.visualBorderWidth' in s
assert 'readonly property real visualBorderWidth: root.activeFocus ? 1' in s
assert 'property color selectedBackground: "transparent"' in s
assert 'property color selectedTextColor: Config.text' in s
assert 'property bool boldWhenSelected: false' in s
assert 'property color persistentSelectedBackground: "transparent"' in s
assert 'property color normalBackground: "transparent"' in s
assert 'color: root.persistentSelectionActive ? root.persistentSelectedBackground' in s
assert 'color: root.selected ? root.effectiveSelectedTextColor : root.normalTextColor' in s
assert 'root.persistentSelectionActive ? root.persistentSelectedBackground' in s
assert 'property bool persistentSelectionHighlight: false' in s
assert 'readonly property bool persistentSelectionActive: root.persistentSelectionHighlight && root.selected' in s
assert 'color: "transparent"' in s
# Selected state is outline/text-only: no resting or selected fill, one-pixel outline.
assert s.count('Rectangle {') >= 2
print('Selected tab uses transparent surfaces, persistent text treatment and a one-pixel outline: OK')
PY
