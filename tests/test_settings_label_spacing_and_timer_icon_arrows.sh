#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TIMERS="$ROOT/components/settings/sections/SettingsTimersSection.qml"
PLAYER="$ROOT/components/settings/sections/SettingsPlayerSection.qml"

# Timer/alarm icon settings and reorder controls share the same row, ordered by screen position.
grep -Fq 'function moveTimerIconOrder(iconId, delta)' "$TIMERS"
grep -Fq 'MoveArrowButton {' "$TIMERS"
grep -Fq 'interactionEnabled: index > 0' "$TIMERS"
grep -Fq 'interactionEnabled: index < 1' "$TIMERS"
grep -Fq 'Config.timerIconOrder === "timer-left" ? ["timer", "alarm"] : ["alarm", "timer"]' "$TIMERS"
grep -Fq 'text: modelData === "alarm" ? "Будильник" : "Таймер"' "$TIMERS"
grep -Fq 'targetProperty: modelData === "timer" ? "timerIconSize" : "timerAlarmIconSize"' "$TIMERS"
grep -Fq 'targetProperty: modelData === "timer" ? "timerIconX" : "timerAlarmIconX"' "$TIMERS"
grep -Fq 'targetProperty: modelData === "timer" ? "timerIconY" : "timerAlarmIconY"' "$TIMERS"
python3 - "$TIMERS" <<'PYCODE'
from pathlib import Path
import re, sys
s = Path(sys.argv[1]).read_text()
start = s.index('model: Config.timerIconOrder === "timer-left" ? ["timer", "alarm"] : ["alarm", "timer"]')
end_match = re.search(
    r'\bSettingsNumberField\s*\{\s*visible:\s*root\.host\.currentOtherTab\s*===\s*1\s*&&\s*root\.host\.currentOtherSubTab\s*===\s*3',
    s[start:]
)
assert end_match, 'Could not locate the next timer layout field after the icon settings'
end = start + end_match.start()
row = s[start:end]
for token in ('SettingsTextField {', 'targetProperty: modelData === "timer" ? "timerIconSize" : "timerAlarmIconSize"', 'targetProperty: modelData === "timer" ? "timerIconX" : "timerAlarmIconX"', 'targetProperty: modelData === "timer" ? "timerIconY" : "timerAlarmIconY"', 'MoveArrowButton {', 'onClicked: root.moveTimerIconOrder(modelData, -1)', 'onClicked: root.moveTimerIconOrder(modelData, 1)'):
    assert token in row, f'Missing timer/alarm icon setting in the shared delegate: {token}'
first_arrow = row.index('MoveArrowButton {')
assert 'Item {' not in row[:first_arrow], 'A flexible spacer is pushing timer/alarm reorder arrows away from the fields'
PYCODE
! grep -Fq 'timerIconOrderCombo' "$TIMERS"
grep -Fq 'Config.timerIconX = Math.round(oldAlarmX)' "$TIMERS"
grep -Fq 'Config.timerAlarmIconX = Math.round(oldTimerX)' "$TIMERS"
grep -Fq 'root.settings.save()' "$TIMERS"

# Progress-tab labels and value fields reserve the same leading label column.
python3 - "$PLAYER" <<'PY'
from pathlib import Path
import sys
s = Path(sys.argv[1]).read_text()
header_start = s.index('text: "Высота"')
header_prefix = s.rfind('Row {', 0, header_start)
assert 'Item { width: 210; height: 24 }' in s[header_prefix:header_start], 'Progress header no longer reserves the label column'
field_start = s.index('value: Config.playerProgressY')
field_prefix = s.rfind('Row {', 0, field_start)
assert 'Item { width: 210; height: 30 }' in s[field_prefix:field_start], 'Progress inputs are not aligned with their labels'
for text in ('text: "Размер"', 'text: "Шрифт"', 'text: "Смещение по Y"', 'text: "Отступ справа"'):
    assert text in s, f'Missing concise Player label: {text}'
for redundant in ('text: "Размер оставшегося времени"', 'text: "Шрифт оставшегося времени"', 'text: "Смещение оставшегося времени по Y"', 'text: "Отступ оставшегося времени справа"'):
    assert redundant not in s, f'Redundant Player label remains: {redundant}'
PY

# Audit each Mopidy Text object: row-label widths should use the shared 210px
# settings label column. Input/combo widths are intentionally not constrained.
python3 - "$ROOT/components/settings/sections/mopidy" <<'PY'
from pathlib import Path
import re, sys
base = Path(sys.argv[1])
violations = []
for path in base.glob('*.qml'):
    source = path.read_text()
    for match in re.finditer(r'\bText\s*\{', source):
        start = match.end()
        depth = 1
        quote = None
        escaped = False
        i = start
        while i < len(source) and depth:
            ch = source[i]
            if quote:
                if escaped:
                    escaped = False
                elif ch == '\\':
                    escaped = True
                elif ch == quote:
                    quote = None
            else:
                if ch in ('"', "'"):
                    quote = ch
                elif ch == '{':
                    depth += 1
                elif ch == '}':
                    depth -= 1
            i += 1
        body = source[start:i-1]
        m = re.search(r'\bwidth\s*:\s*(\d+)', body)
        if m and m.group(1) in {'180', '220'}:
            line = source.count('\n', 0, match.start()) + 1
            violations.append(f'{path.name}:{line} Text width {m.group(1)}')
if violations:
    raise SystemExit('Inconsistent Mopidy setting-label widths:\n' + '\n'.join(violations))
PY

grep -Fq 'Показывать оставшееся время трека' "$ROOT/components/settings/sections/mopidy/SettingsMopidyTimeSection.qml"
grep -Fq 'Показывать оставшееся время альбома' "$ROOT/components/settings/sections/mopidy/SettingsMopidyTimeSection.qml"
grep -Fq 'text: "Выравнивание"' "$ROOT/components/settings/sections/mopidy/SettingsMopidyTimeSection.qml"
grep -Fq 'Переключать Mopidy по ПКМ на Player' "$ROOT/components/settings/sections/mopidy/SettingsMopidySection.qml"

echo 'settings labels, alignment, and timer icon reorder: OK'

# The shared arrow primitive hides unavailable directions by default.
MOVE="$ROOT/components/primitives/MoveArrowButton.qml"
grep -Fq 'visible: root.requestedVisible && (!root.hideWhenDisabled || root.interactionEnabled)' "$MOVE"
