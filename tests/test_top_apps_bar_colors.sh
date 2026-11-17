#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="$ROOT/Config.qml"
DEFAULTS="$ROOT/js/settings/SettingsDefaults.js"
META="$ROOT/js/settings/SettingsMetadata.js"
COLORS="$ROOT/components/settings/sections/SettingsColorsSection.qml"
TOP_SETTINGS="$ROOT/components/settings/sections/SettingsCpuRamSection.qml"
TOP="$ROOT/components/TopApps.qml"
THEMES="$ROOT/js/settings/SettingsThemes.js"
MANAGER="$ROOT/js/settings/SettingsThemeManager.js"
SCHEMA="$ROOT/js/settings/SettingsSchema.js"
PERSIST="$ROOT/js/settings/SettingsPersistence.js"
for key in topAppsCpuBarColor topAppsRamBarColor topAppsCpuBarTrackColor topAppsRamBarTrackColor; do
    grep -Fq "property color $key:" "$CONFIG" || { echo "$key Config property is missing" >&2; exit 1; }
    grep -Fq "$key:" "$DEFAULTS" || { echo "$key default is missing" >&2; exit 1; }
    grep -Fq "$key" "$META" || { echo "$key is not tracked as a color" >&2; exit 1; }
    grep -Fq "$key" "$TOP_SETTINGS" || { echo "$key is not exposed in Top Apps settings" >&2; exit 1; }
    grep -Fq "$key" "$TOP" || { echo "$key is not used by Top Apps" >&2; exit 1; }
done
grep -Fq 'Цвета полос нагрузки' "$TOP_SETTINGS" || { echo 'Top Apps bar color section is not clearly labelled' >&2; exit 1; }
grep -Fq 'label: "CPU: цвет полосы"' "$TOP_SETTINGS" || { echo 'CPU color field is missing from Top Apps settings' >&2; exit 1; }
grep -Fq 'label: "RAM: цвет полосы"' "$TOP_SETTINGS" || { echo 'RAM color field is missing from Top Apps settings' >&2; exit 1; }
python3 - "$TOP_SETTINGS" <<'PYVIS'
from pathlib import Path
import sys
s=Path(sys.argv[1]).read_text()
toggle=s.index('text: "Показывать полосы нагрузки"')
heading=s.index('heading: "Цвета полос нагрузки"', toggle)
other=s.index('text: "Показывать строку «Система/прочее»"', heading)
if not (toggle < heading < other):
    raise SystemExit('bar colors are not located directly after the bar visibility toggle')
expected=('Отдельные цвета для заполнения полос CPU и RAM.','CPU: цвет полосы','RAM: цвет полосы')
morph_start=s.index('id: topAppsBarColorsMorph')
morph_end=s.index('id: topAppsBarColorsGroup', morph_start)
morph=s[morph_start:morph_end]
if 'Config.topAppsShowBars && host.currentPageId === "cpuRam" && host.currentPageSubTabIndex === 2' not in morph:
    raise SystemExit('bar color morph does not follow the Top Apps visibility toggle')
if 'progress: Config.topAppsShowBars ? 1 : 0' not in morph:
    raise SystemExit('bar color section does not animate its geometry')
for label in expected:
    if label not in s[heading:other]:
        raise SystemExit(f'{label} is missing from the animated color section')
print('Top Apps bar color controls follow the Show bars option: OK')
PYVIS
if grep -Fq 'label: "CPU: цвет полосы"' "$COLORS" || grep -Fq 'label: "RAM: цвет полосы"' "$COLORS"; then echo 'Top Apps colors should not remain in the Colors tab' >&2; exit 1; fi
grep -Fq 'colors[owner.colorNames[j]] = String(config[owner.colorNames[j]])' "$PERSIST" || { echo 'Color persistence no longer includes colorNames' >&2; exit 1; }
grep -Fq 'if (fallbackKey === "topAppsCpuBarColor" && savedPalette.accent !== undefined)' "$SCHEMA" || { echo 'Old custom themes do not inherit CPU bar color fallback' >&2; exit 1; }
grep -Fq 'else if (fallbackKey === "topAppsRamBarColor" && savedPalette.ram !== undefined)' "$SCHEMA" || { echo 'Old custom themes do not inherit RAM bar color fallback' >&2; exit 1; }
grep -Fq 'else if ((fallbackKey === "topAppsCpuBarTrackColor" || fallbackKey === "topAppsRamBarTrackColor")' "$SCHEMA" || { echo 'Old custom themes do not inherit inactive bar color fallback' >&2; exit 1; }
python3 - "$THEMES" <<'PY'
from pathlib import Path
import sys
s=Path(sys.argv[1]).read_text()
for key in ('topAppsCpuBarColor','topAppsRamBarColor','topAppsCpuBarTrackColor','topAppsRamBarTrackColor'):
    count=s.count(key)
    if count != 11: raise SystemExit(f'{key}: expected 11 built-in theme entries, found {count}')
print('Top Apps bar colors are independently configurable, persisted and included in built-in themes: OK')
PY
