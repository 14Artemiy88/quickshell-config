#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WINDOW="$ROOT/components/settings/sections/SettingsWindowSection.qml"
WIDGET="$ROOT/components/settings/SettingsNavigation.qml"
fail() { echo "Settings search options group animation: FAIL: $*" >&2; exit 1; }

# Search visibility and its appearance preferences form one independent framed group.
python3 - "$WINDOW" <<'PY'
from pathlib import Path
import sys
s = Path(sys.argv[1]).read_text()
start = s.index('heading: "Поиск"')
end = s.index('SettingsGroup {', start)
block = s[start:end]
for expected in (
    'changeKeys: ({ keys: ["settingsSearchVisible", "settingsSearchHighlightColor", "settingsSearchHighlightBorderWidth", "settingsSearchMatchCountFontSize"] })',
    'text: "Показывать поиск в боковой панели"',
    'label: "Цвет рамки совпадений поиска"',
    'label: "Толщина рамки совпадений"',
    'label: "Размер шрифта счётчиков"',
    'targetProperty: "settingsSearchMatchCountFontSize"',
    'height: Config.settingsSearchVisible ? implicitHeight : 0',
    'opacity: Config.settingsSearchVisible ? 1 : 0',
    'enabled: Config.settingsSearchVisible',
    'Behavior on height',
    'Behavior on opacity',
    'Config.animationDuration(180, "size")',
    'Config.animationDuration(140, "appearance")',
):
    assert expected in block, f'search group missing {expected}'
assert block.index('text: "Показывать поиск в боковой панели"') < block.index('height: Config.settingsSearchVisible ? implicitHeight : 0'), 'search toggle must remain visible above conditional options'
assert 'settingsSearchHighlightColor' not in s[:start], 'search color remains in the general settings frame'
assert 'settingsSearchHighlightBorderWidth' not in s[:start], 'search border width remains in the general settings frame'
PY

# Sidebar search bar and the spacing below it collapse/fade using shared animation settings.
python3 - "$WIDGET" <<'PY'
from pathlib import Path
import sys
s = Path(sys.argv[1]).read_text()
start = s.index('id: root')
end = s.index('id: mainSettingsTabs', start)
block = s[start:end]
for expected in (
    'id: settingsSearchContainer',
    'height: Config.settingsSearchVisible ? 30 : 0',
    'opacity: Config.settingsSearchVisible ? 1 : 0',
    'Behavior on height',
    'Behavior on opacity',
    'spacing: Config.settingsSearchVisible ? 8 : 0',
):
    assert expected in block, f'sidebar search animation missing {expected}'
PY

grep -Fq 'host.clearSettingsSearchQuery()' "$WINDOW" || fail 'hiding search does not clear stale query'
grep -Fq 'settingsSearchVisible' "$WINDOW" || fail 'search settings are not in Settings Window'
echo 'settings search options group and animations: OK'
