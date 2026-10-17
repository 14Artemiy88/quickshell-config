#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "Top Apps settings grouping: FAIL: $*" >&2; exit 1; }
config="$ROOT/Config.qml"
defaults="$ROOT/js/settings/SettingsDefaults.js"
persist="$ROOT/js/settings/SettingsPersistence.js"
apply="$ROOT/js/settings/SettingsApplySystemVisual.js"
resets="$ROOT/js/settings/SettingsResets.js"
ui="$ROOT/components/settings/sections/SettingsCpuRamSection.qml"
widget="$ROOT/components/TopApps.qml"
for key in topAppsCpuHeaderTitle topAppsCpuHeaderSubtitle topAppsRamHeaderTitle topAppsRamHeaderSubtitle; do
    grep -Fq "property string $key:" "$config" || fail "$key Config property missing"
    grep -Fq "$key:" "$defaults" || fail "$key defaults missing"
    grep -Fq "$key: config.$key" "$persist" || fail "$key is not persisted"
    grep -Fq 'o[thname] !== undefined' "$apply" || fail "$key is not restored from settings"
    grep -Fq "$key" "$resets" || fail "$key is not included in module/reset profiles"
    grep -Fq "Config.$key" "$widget" || fail "$key is not used by Top Apps rendering"
done
for key in topAppsHeaderTitleFontSize topAppsHeaderSubtitleFontSize; do
    grep -Fq "property int $key:" "$config" || fail "$key Config property missing"
    grep -Fq "$key:" "$defaults" || fail "$key defaults missing"
    grep -Fq "$key: config.$key" "$persist" || fail "$key is not persisted"
    grep -Fq "$key" "$apply" || fail "$key is not restored"
    grep -Fq "$key" "$resets" || fail "$key is not included in reset profiles"
    grep -Fq "$key" "$ui" || fail "$key settings UI is missing"
    grep -Fq "Config.$key" "$widget" || fail "$key is not used by header rendering"
done
python3 - "$ui" <<'PY'
from pathlib import Path
import sys
s=Path(sys.argv[1]).read_text()
checks = [
    ('Показывать заголовки CPU и памяти', 'Настройки заголовков', 'Config.topAppsShowHeaders && host.currentOtherTab === 5 && host.currentOtherSubTab === 2'),
    ('Показывать полосы нагрузки', 'Цвета полос нагрузки', 'Config.topAppsShowBars && host.currentOtherTab === 5 && host.currentOtherSubTab === 2'),
    ('Показывать строку «Система/прочее»', 'Настройки строки «Система/прочее»', 'Config.topAppsShowSystemRemainder && host.currentOtherTab === 5 && host.currentOtherSubTab === 2'),
]
for toggle, group, guard in checks:
    a=s.index('text: "'+toggle+'"')
    b=s.index('text: "'+group+'"', a)
    if b <= a: raise SystemExit(f'{group} does not follow its toggle')
    if guard not in s[a:b]: raise SystemExit(f'{group} is not guarded by its controlling option')
# Each heading editor/size setting must collapse with the main header toggle.
for label in ('Основной заголовок', 'Подзаголовок', 'Размер основного заголовка', 'Размер подзаголовка'):
    pos=s.index('text: "'+label+'"')
    row_start=s.rfind('    Row {',0,pos)
    row_end=s.find('\n    }',pos)
    if 'Config.topAppsShowHeaders && host.currentOtherTab === 5 && host.currentOtherSubTab === 2' not in s[row_start:row_end+6]:
        raise SystemExit(f'{label} does not follow the header visibility option')
pos=s.index('text: "Название строки остатка"')
row_start=s.rfind('    Row {',0,pos)
row_end=s.find('\n    }',pos)
if 'Config.topAppsShowSystemRemainder && host.currentOtherTab === 5 && host.currentOtherSubTab === 2' not in s[row_start:row_end+6]:
    raise SystemExit('Other label editor is not conditioned on its toggle')
print('Top Apps settings are grouped under their controlling toggles: OK')
PY

echo "Top Apps settings grouping: OK"
