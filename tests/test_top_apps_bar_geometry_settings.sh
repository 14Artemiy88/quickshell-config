#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "Top Apps bar geometry: FAIL: $*" >&2; exit 1; }
config="$ROOT/Config.qml"
defaults="$ROOT/js/settings/SettingsDefaults.js"
apply="$ROOT/js/settings/SettingsApplySystemVisual.js"
persist="$ROOT/js/settings/SettingsPersistence.js"
resets="$ROOT/js/settings/SettingsResets.js"
settings="$ROOT/components/settings/sections/SettingsCpuRamSection.qml"
widget="$ROOT/components/TopApps.qml"

for key in topAppsBarX topAppsBarY topAppsBarHeight topAppsBarWidth; do
    grep -Fq "property int $key:" "$config" || fail "$key Config property missing"
    grep -Fq "$key:" "$defaults" || fail "$key default missing"
    grep -Fq "$key: config.$key" "$persist" || fail "$key is not persisted"
    grep -Fq "$key" "$apply" || fail "$key is not restored and bounded"
    grep -Fq "targetProperty: \"$key\"" "$settings" || fail "$key settings field missing"
    grep -Fq "Config.$key" "$widget" || fail "$key is not used by rendering"
    grep -Fq "\"$key\"" "$resets" || fail "$key missing from profile reset"
done

for label in 'X — положение по горизонтали' 'Y — смещение по вертикали' 'Высота полосы' 'Длина полосы'; do
    grep -Fq "text: \"$label\"" "$settings" || fail "settings label '$label' missing"
done

grep -Fq '["topAppsBarX", 45, 240]' "$apply" || fail "X range is not bounded"
grep -Fq '["topAppsBarY", -10, 10]' "$apply" || fail "Y range is not bounded"
grep -Fq '["topAppsBarHeight", 1, 30]' "$apply" || fail "height range is not bounded"
grep -Fq '["topAppsBarWidth", 1, 300]' "$apply" || fail "width range is not bounded"
grep -Fq 'y: Math.round((appRow.height - height) / 2) + Number(Config.topAppsBarY)' "$widget" || fail "bar Y is not centered relative to text"
grep -Fq 'radius: Math.min(3, parent.height / 2)' "$widget" || fail "bar radius does not adapt to configured height"
grep -Fq 'property int barStartX: Math.max(45, Number(Config.topAppsBarX))' "$widget" || fail "bar X is being clamped by available row width"
grep -Fq 'width: Math.max(1, Number(Config.topAppsBarWidth))' "$widget" || fail "configured bar width is being clamped by available row width"
grep -Fq 'contentWidth: Math.max(Settings.geometry.topAppsCpu[2], topAppsCpuView.requiredContentWidth)' "$ROOT/shell.qml" || fail "CPU Top Apps host window does not grow to show the full bar"
grep -Fq 'contentWidth: Math.max(Settings.geometry.topAppsRam[2], topAppsRamView.requiredContentWidth)' "$ROOT/shell.qml" || fail "RAM Top Apps host window does not grow to show the full bar"
grep -Fq 'readonly property int layoutContentWidth:' "$widget" || fail "logical module width is missing"
grep -Fq 'x: root.layoutRowWidth - width' "$widget" || fail "value column is not fixed to logical width"
grep -Fq 'visible: Config.topAppsShowBars && host.currentOtherTab === 5 && host.currentOtherSubTab === 2' "$settings" || fail "geometry settings are not limited to Top Apps with bars enabled"

echo "Top Apps bar geometry settings: OK"
