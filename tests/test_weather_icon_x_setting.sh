#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import re, sys
root = Path(sys.argv[1])
config = (root / 'Config.qml').read_text(encoding='utf-8')
defaults = (root / 'js/settings/SettingsDefaults.js').read_text(encoding='utf-8')
section = (root / 'components/settings/sections/SettingsWeatherSection.qml').read_text(encoding='utf-8')
weather = (root / 'components/WeatherNow.qml').read_text(encoding='utf-8')
apply = (root / 'js/settings/SettingsApplyWeather.js').read_text(encoding='utf-8')
persist = (root / 'js/settings/SettingsPersistence.js').read_text(encoding='utf-8')
resets = (root / 'js/settings/SettingsResets.js').read_text(encoding='utf-8')

assert re.search(r'property int weatherIconX:\s*113\b', config), 'Config.qml must define a compatible default X position'
assert re.search(r'weatherIconX:\s*113\b', defaults), 'settings defaults must include weatherIconX'
assert re.search(r'\bx:\s*Config\.weatherIconX\b', weather), 'current weather image must use weatherIconX'
assert 'text: "X"' in section and 'targetProperty: "weatherIconX"' in section, 'settings must expose the X position editor'
assert 'id: weatherIconXField' in section and 'value: Config.weatherIconX' in section, 'X field must read current config value'
assert '["weatherIconX", 0, 500]' in apply, 'X position needs bounded settings validation'
assert 'weatherIconX: config.weatherIconX' in persist, 'X position must be persisted'
assert '"weatherIconSize", "weatherIconX"' in resets, 'weather reset lists must include weatherIconX'
assert resets.count('"weatherIconX"') >= 2, 'both module reset and Weather reset paths must include weatherIconX'
assert section.count('targetProperty: "weatherIconX"') == 1, 'there must be exactly one X position editor'

# Lightweight delimiter validation for the touched QML component.
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
print('Weather current-icon X position setting: OK')
PY
