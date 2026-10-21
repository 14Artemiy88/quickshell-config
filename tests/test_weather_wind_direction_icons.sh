#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WEATHER="$ROOT/components/WeatherNow.qml"
SECTION="$ROOT/components/settings/sections/SettingsWeatherSection.qml"
ROW="$ROOT/components/settings/sections/WeatherWindDirectionSettingsRow.qml"
DEFAULTS="$ROOT/js/settings/SettingsDefaults.js"
CONFIG="$ROOT/Config.qml"
APPLY="$ROOT/js/settings/SettingsApplyWeather.js"
PERSIST="$ROOT/js/settings/SettingsPersistence.js"
RESETS="$ROOT/js/settings/SettingsResets.js"
for file in "$WEATHER" "$SECTION" "$ROW" "$DEFAULTS" "$CONFIG" "$APPLY" "$PERSIST" "$RESETS"; do test -f "$file"; done

python3 - "$ROOT" <<'PY'
from pathlib import Path
import re, sys
root=Path(sys.argv[1])
paths={
 'weather':root/'components/WeatherNow.qml',
 'section':root/'components/settings/sections/SettingsWeatherSection.qml',
 'row':root/'components/settings/sections/WeatherWindDirectionSettingsRow.qml',
 'defaults':root/'js/settings/SettingsDefaults.js',
 'config':root/'Config.qml',
 'apply':root/'js/settings/SettingsApplyWeather.js',
 'persist':root/'js/settings/SettingsPersistence.js',
 'resets':root/'js/settings/SettingsResets.js',
}
s={k:p.read_text(encoding='utf-8') for k,p in paths.items()}
directions=[
 ('Calm','Без направления (0)',''),('N','Север (1)','↑'),('NE','Северо-восток (2)','↗'),
 ('E','Восток (3)','→'),('SE','Юго-восток (4)','↘'),('S','Юг (5)','↓'),
 ('SW','Юго-запад (6)','↙'),('W','Запад (7)','←'),('NW','Северо-запад (8)','↖')]
# Verify all nine icon/font pairs are defined and flow through persistence, apply, and profile reset.
for key,label,glyph in directions:
    for kind in ('Icon','Font'):
        prop=f'weatherWind{key}{kind}'
        assert f'property string {prop}:' in s['config'], f'Config missing {prop}'
        assert re.search(rf'\b{prop}:', s['defaults']), f'default missing {prop}'
        assert f'{prop}: config.{prop}' in s['persist'], f'snapshot missing {prop}'
        assert f'"{prop}"' in s['resets'], f'reset/profile handling missing {prop}'
        assert f'\"{key}\"' in s['apply'] and 'weatherWindIconKey' in s['apply'] and 'weatherWindFontKey' in s['apply'], f'apply loop missing {key}'
    assert f'windDirectionKey' in s['weather']
    assert label in s['section'], f'settings UI missing direction {label}'
    assert f'Config.weatherWind{key}Icon' in s['section']
    assert f'Config.weatherWind{key}Font' in s['section']
assert s['section'].count('WeatherWindDirectionSettingsRow {') == 9, 'expected nine configurable direction rows'
assert 'function windIcon(scale)' in s['weather'] and 'function windFont(scale)' in s['weather']
assert 'rotation:' not in s['weather'] and 'windAngle' not in s['weather'], 'wind glyph must not be rotated'
assert 'font.family: root.windFont(root.weather.wind?.direction?.scale_8)' in s['weather']
assert 'text: root.windIcon(root.weather.wind?.direction?.scale_8)' in s['weather']
assert 'signal iconEdited(string value)' in s['row'] and 'signal fontEdited(string value)' in s['row']
assert 'onIconValueChanged' in s['row'] and 'onFontValueChanged' in s['row']
assert 'font.family: root.fontValue || Config.font' in s['row'], 'icon field should preview the chosen direction font'

# Basic delimiter balancing for edited QML/JS helps catch accidental malformed patches.
pairs={')':'(',']':'[','}':'{'}
def balanced(name, source):
    stack=[]; quote=None; escaped=False; line_comment=False; block_comment=False; i=0
    while i < len(source):
        c=source[i]; n=source[i+1] if i+1<len(source) else ''
        if line_comment:
            if c=='\n': line_comment=False
            i+=1; continue
        if block_comment:
            if c=='*' and n=='/': block_comment=False; i+=2; continue
            i+=1; continue
        if quote:
            if escaped: escaped=False
            elif c=='\\': escaped=True
            elif c==quote: quote=None
            i+=1; continue
        if c=='/' and n=='/': line_comment=True; i+=2; continue
        if c=='/' and n=='*': block_comment=True; i+=2; continue
        if c in ('"',"'",'`'): quote=c; i+=1; continue
        if c in '([{': stack.append((c,i))
        elif c in ')]}':
            if not stack or stack[-1][0] != pairs[c]: raise SystemExit(f'{name}: unmatched {c} at {i}')
            stack.pop()
        i+=1
    if stack: raise SystemExit(f'{name}: unclosed {stack[-1][0]} at {stack[-1][1]}')
for key in ('weather','section','row','defaults','config','apply','persist','resets'):
    balanced(str(paths[key]),s[key])
print('Weather wind direction glyphs, font settings, persistence, profiles and non-rotating rendering: OK')
PY

echo 'Weather wind direction icon/font settings test: OK'
