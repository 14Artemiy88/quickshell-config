#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QML="$ROOT/components/settings/sections/SettingsTimersSection.qml"
fail() { echo "Timer finished-image options MorphGeometry: FAIL: $*" >&2; exit 1; }

grep -Fq 'import "../../primitives"' "$QML" || fail "shared MorphGeometry import missing"
for token in \
    'id: timerFinishedImageOptionsMorph' \
    'id: timerFinishedImageOptionsContent' \
    'visible: Config.timerFinishedImageEnabled || normalizedProgress > 0.001' \
    'fromGeometry: Qt.rect(0, 0, parent.width, 0)' \
    'toGeometry: Qt.rect(0, 0, parent.width, timerFinishedImageOptionsContent.implicitHeight)' \
    'progress: Config.timerFinishedImageEnabled ? 1 : 0' \
    'animationDuration: Config.animationDuration(180, "appearance")' \
    'animationEasing: Config.animationEasingType("standard", Config.timerFinishedImageEnabled ? "enter" : "exit")'; do
    grep -Fq "$token" "$QML" || fail "missing $token"
done
python3 - "$QML" <<'PYTEST'
from pathlib import Path
import sys
s = Path(sys.argv[1]).read_text()
needle = 'MorphGeometry {\n            id: timerFinishedImageOptionsMorph'
start = s.find(needle)
assert start >= 0, 'timer finished-image MorphGeometry not found'
brace = s.find('{', start)
depth = 0
end = None
for i in range(brace, len(s)):
    if s[i] == '{':
        depth += 1
    elif s[i] == '}':
        depth -= 1
        if depth == 0:
            end = i + 1
            break
assert end is not None, 'MorphGeometry block is not balanced'
block = s[start:end]
for label in ('Ширина изображения', 'Отступ изображения', 'Цвет заголовка',
             'Свой цвет заголовка', 'Размер заголовка', 'Шрифт заголовка',
             'Расположение заголовка'):
    assert block.count(f'label: "{label}"') == 1, f'{label} row missing or duplicated'
assert block.count('visible:') == 2, 'only the morph wrapper and custom-title-color row should control visibility'
assert 'visible: !Config.timerFinishedTitleUsesTimerColor' in block, 'custom title color should remain independently conditional'
for prop in ('timerFinishedImageWidth', 'timerFinishedImageMargin', 'timerFinishedTitleColor',
             'timerFinishedTitleFontSize', 'timerFinishedTitleFont', 'timerFinishedTitleAlignment'):
    assert prop in block, f'{prop} binding missing from morph content'
assert 'Config.timerFinishedImageEnabled &&' not in block, 'child rows must remain alive during exit morph'
checkbox_area = s[s.find('text: "Оформление и показ"'):start]
assert 'text: "Показывать изображение"' in checkbox_area, 'image enable checkbox was moved or removed'
assert 'checked: Config.timerFinishedImageEnabled' in checkbox_area, 'image enable binding changed'
assert 'Config.timerFinishedImageEnabled = checked' in checkbox_area, 'image enable setting action changed'
path_row = s[s.find('label: "Путь к изображению"'):start]
assert 'enabled: Config.timerFinishedImageEnabled' in path_row, 'image path field should remain in place and disabled when image is off'
assert 'label: "Цвет рамки окна"' in s[end:], 'following static settings row was moved or removed'
PYTEST
printf 'Timer finished-image options MorphGeometry integration: OK\n'
