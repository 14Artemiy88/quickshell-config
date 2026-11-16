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
    ('Показывать заголовки CPU и памяти', 'Заголовки', 'Config.topAppsShowHeaders && host.currentOtherTab === 5 && host.currentOtherSubTab === 2'),
    ('Показывать полосы нагрузки', 'Положение и размер полос', 'Config.topAppsShowBars && host.currentOtherTab === 5 && host.currentOtherSubTab === 2'),
    ('Показывать полосы нагрузки', 'Цвета полос нагрузки', 'Config.topAppsShowBars && host.currentOtherTab === 5 && host.currentOtherSubTab === 2'),
    ('Показывать строку «Система/прочее»', 'Строка «Система/прочее»', 'Config.topAppsShowSystemRemainder && host.currentOtherTab === 5 && host.currentOtherSubTab === 2'),
]
for toggle, group, guard in checks:
    if 'text: "'+toggle+'"' not in s:
        raise SystemExit(f'missing controlling toggle: {toggle}')
    if 'heading: "'+group+'"' not in s:
        raise SystemExit(f'{group} is not declared as an explicit SettingsGroup legend')
    # The legend remains visible with the frame; only dependent controls use the toggle guard.
    heading_at = s.index('heading: "'+group+'"')
    if group in ('Положение и размер полос', 'Цвета полос нагрузки'):
        morph_id = 'topAppsBarGeometryMorph' if group == 'Положение и размер полос' else 'topAppsBarColorsMorph'
        morph_start = s.index('id: '+morph_id)
        morph_end = s.find('\n    }', morph_start)
        morph_block = s[morph_start:morph_end + 6]
        if guard not in morph_block:
            raise SystemExit(f'{group} morph is not guarded by its controlling option')
    else:
        group_start = s.rfind('SettingsGroup {', 0, heading_at)
        group_end = s.find('\n    }', heading_at)
        group_block = s[group_start:group_end + 6]
        toggle_key = 'topAppsShowHeaders' if group == 'Заголовки' else 'topAppsShowSystemRemainder'
        if f'progress: Config.{toggle_key} ? 1 : 0' not in group_block or 'normalizedProgress > 0.001' not in group_block:
            raise SystemExit(f'{group} dependent controls are not guarded by a complete enter/exit morph')
# Header and remainder dependent fields now collapse through shared morph blocks,
# so the controls themselves must not be gated with immediate visible bindings.
headers_start = s.index('id: topAppsHeadersMorph')
headers_end = s.index('\n        }', headers_start)  # closing MorphGeometry wrapper
headers_block = s[headers_start:headers_end]
for label in ('Основной заголовок', 'Подзаголовок', 'Размер основного заголовка', 'Размер подзаголовка'):
    if 'text: "'+label+'"' not in headers_block:
        raise SystemExit(f'{label} is missing from the animated header block')
if 'visible: Config.topAppsShowHeaders' in headers_block:
    raise SystemExit('header children still disappear before the morph finishes')
remainder_start = s.index('id: topAppsSystemRemainderMorph')
remainder_end = s.index('\n        }', remainder_start)
remainder_block = s[remainder_start:remainder_end]
if 'Название строки остатка' not in remainder_block or 'topAppsSystemRemainderLabelField' not in remainder_block:
    raise SystemExit('Other row label editor is missing from its animated block')
if 'visible: Config.topAppsShowSystemRemainder' in remainder_block:
    raise SystemExit('Other row child still disappears before the morph finishes')

PY
echo "Top Apps settings grouping: OK"
