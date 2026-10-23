#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
from collections import Counter
import re, sys
root = Path(sys.argv[1])
section_path = root / 'components/settings/sections/SettingsWeatherSection.qml'
section = section_path.read_text(encoding='utf-8')

assert 'property bool windDirectionSettingsExpanded: false' in section, 'wind glyph controls should start collapsed'
assert 'id: windDirectionSettingsHeader' in section, 'missing compact group header'
assert 'cursorShape: Qt.PointingHandCursor' in section, 'group header must look clickable'
assert 'onClicked: weatherSection.windDirectionSettingsExpanded = !weatherSection.windDirectionSettingsExpanded' in section, 'group header does not toggle expanded state'
assert 'text: "Иконки направления ветра"' in section, 'group label missing'
assert 'Иконки и шрифты направления ветра' not in section, 'old expanded label should be removed'
assert section.index('text: "Иконки направления ветра"') < section.index('heading: "Иконка текущей погоды"'), 'wind icon dropdown must be first in the current-weather subtab'
assert '9 направлений · нажмите' not in section, 'dropdown title should not keep the old subtitle'
assert section.count('WeatherWindDirectionSettingsRow {') == 9, 'all nine direction-specific rows must remain available'
assert section.count('weatherSection.windDirectionSettingsExpanded') >= 11, 'the group state must control all direction settings and header'

# Current-weather geometry uses consistent aligned table headers instead of labels embedded in each row.
for heading in ('Y', 'Размер', 'Смещение Y', 'Зазор', 'Ширина', 'Высота', 'Шрифт'):
    assert f'text: "{heading}"' in section, f'missing table heading {heading}'
assert 'text: "Иконка"' in section, 'icon geometry row missing'
assert 'heading: "Положение элементов"' in section, 'position controls should use the frame heading'
assert section.count('id: weatherIconYField') == 1 and section.count('id: weatherIconSizeField') == 1
assert section.count('targetProperty: "weatherWindColumnX"') == 1, 'duplicate wind-column X editor must be removed'

# Each setting should have a single editor in this subtab, preventing conflicting duplicate controls.
targets = re.findall(r'targetProperty:\s*"([^"]+)"', section)
duplicates = [name for name, count in Counter(targets).items() if count > 1]
assert not duplicates, f'duplicate settings editors remain: {duplicates}'

# Simple delimiter check for the edited QML source.
pairs = {')':'(', ']':'[', '}':'{'}
stack=[]; quote=None; escaped=False; line_comment=False; block_comment=False; i=0
while i < len(section):
    c=section[i]; n=section[i+1] if i+1 < len(section) else ''
    if line_comment:
        if c == '\n': line_comment=False
        i += 1; continue
    if block_comment:
        if c == '*' and n == '/': block_comment=False; i += 2; continue
        i += 1; continue
    if quote:
        if escaped: escaped=False
        elif c == '\\': escaped=True
        elif c == quote: quote=None
        i += 1; continue
    if c == '/' and n == '/': line_comment=True; i += 2; continue
    if c == '/' and n == '*': block_comment=True; i += 2; continue
    if c in ('"', "'", '`'): quote=c; i += 1; continue
    if c in '([{': stack.append((c, i))
    elif c in ')]}':
        assert stack and stack[-1][0] == pairs[c], f'unmatched {c} at {i}'
        stack.pop()
    i += 1
assert not stack, f'unclosed delimiter {stack[-1]}'
print('Weather settings cleanup (collapsible wind glyphs, grouped icon geometry, no duplicate editors): OK')
PY
