#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "Top Apps typography settings: FAIL: $*" >&2; exit 1; }
config="$ROOT/Config.qml"
defaults="$ROOT/js/settings/SettingsDefaults.js"
apply="$ROOT/js/settings/SettingsApplySystemVisual.js"
persist="$ROOT/js/settings/SettingsPersistence.js"
resets="$ROOT/js/settings/SettingsResets.js"
ui="$ROOT/components/TopApps.qml"
settings="$ROOT/components/settings/sections/SettingsCpuRamSection.qml"

for spec in 'topAppsFont: string' 'topAppsFontSize: int' 'topAppsRowSpacing: int' 'topAppsTopOffset: int'; do
    key="${spec%%:*}"
    type="${spec#*: }"
    grep -Fq "property $type $key" "$config" || fail "$key Config property is missing"
    grep -Fq "$key:" "$defaults" || fail "$key default is missing"
    grep -Fq "$key: config.$key" "$persist" || fail "$key is not persisted"
    grep -Fq "$key" "$resets" || fail "$key is missing from reset handling"
done

grep -Fq 'if (o.topAppsFont !== undefined) Config.topAppsFont = String(o.topAppsFont).slice(0, 128)' "$apply" || fail "font family is not restored"
grep -Fq '["topAppsFontSize", 1, Infinity]' "$apply" || fail "font size should have no artificial upper bound"
grep -Fq '["topAppsRowSpacing", 0, Infinity]' "$apply" || fail "line spacing should have no artificial upper bound"
grep -Fq '["topAppsTopOffset", 0, Infinity]' "$apply" || fail "top offset setting is not applied without an artificial upper bound"

grep -Fq 'text: "Шрифт списка (пусто — системный)"' "$settings" || fail "font setting is missing"
grep -Fq 'text: "Размер шрифта списка"' "$settings" || fail "font size setting is missing"
grep -Fq 'text: "Межстрочный интервал"' "$settings" || fail "line spacing setting is missing"
grep -Fq 'text: "Отступ от верхнего края"' "$settings" || fail "top offset setting is missing"
grep -Fq 'onEditingFinished:' "$settings" || fail "font field does not commit edits"
grep -Fq 'targetProperty: "topAppsFontSize"' "$settings" || fail "font size field is not bound to Config"
grep -Fq 'targetProperty: "topAppsRowSpacing"' "$settings" || fail "line spacing field is not bound to Config"
grep -Fq 'targetProperty: "topAppsTopOffset"' "$settings" || fail "top offset field is not bound to Config"

grep -Fq 'height: Config.topAppsShowHeaders ? 12 : 0' "$ui" || fail "hidden headers still reserve vertical space"
grep -Fq 'clip: true' "$ui" || fail "Top Apps rows/header should be clipped within their layout containers"
grep -Fq 'readonly property int displayFontSize: Math.max(1, Math.round(Number(Config.topAppsFontSize)' "$ui" || fail "font size is still clamped by the generic UI font helper"
grep -Fq 'anchors.topMargin: Math.min(Math.max(0, Config.topAppsTopOffset)' "$ui" || fail "configurable top offset is not applied safely"
grep -Fq 'font.family: root.displayFontFamily' "$ui" || fail "configurable font family is not applied to labels"
grep -Fq 'spacing: Config.topAppsRowSpacing' "$ui" || fail "configurable row spacing is not applied"
grep -Fq 'readonly property int displayRowHeight: Math.max(1, displayFontSize + 2)' "$ui" || fail "row height does not follow configured font size"
grep -Fq 'height: root.displayRowHeight' "$ui" || fail "rows do not use the calculated row height"

grep -Fq 'moduleName === "topAppsCpu" || moduleName === "topAppsRam"' "$resets" || fail "Top Apps CPU/RAM module reset branch is missing"
for key in topAppsShowHeaders topAppsShowBars topAppsShowSystemRemainder topAppsSystemRemainderLabel topAppsFont topAppsFontSize topAppsRowSpacing topAppsTopOffset; do grep -Fq '"'$key'"' "$resets" || fail "Top Apps module reset misses $key"; done
for key in cpuShowRam topAppsShowHeaders topAppsShowBars topAppsShowSystemRemainder topAppsSystemRemainderLabel topAppsFont topAppsFontSize topAppsRowSpacing topAppsTopOffset; do grep -Fq '"'$key'"' "$resets" || fail "CPU/RAM reset misses $key"; done

echo "Top Apps typography settings: OK"
