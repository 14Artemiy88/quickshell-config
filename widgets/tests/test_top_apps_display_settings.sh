#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "Top Apps display settings: FAIL: $*" >&2; exit 1; }

config="$ROOT/Config.qml"
defaults="$ROOT/js/settings/SettingsDefaults.js"
apply="$ROOT/js/settings/SettingsApplySystemVisual.js"
persist="$ROOT/js/settings/SettingsPersistence.js"
resets="$ROOT/js/settings/SettingsResets.js"
ui="$ROOT/components/TopApps.qml"
settings_ui="$ROOT/components/settings/SettingsWidget.qml"
settings_section="$ROOT/components/settings/sections/SettingsCpuRamSection.qml"

for key in topAppsShowHeaders topAppsShowBars; do
    grep -Fq "property bool $key: true" "$config" || fail "$key Config default is missing"
    grep -Fq "$key: true" "$defaults" || fail "$key defaultConfig value is missing"
    grep -Fq "if (o.$key !== undefined) Config.$key = !!o.$key" "$apply" || fail "$key is not restored from settings"
    grep -Fq "$key: config.$key" "$persist" || fail "$key is not persisted"
    grep -Fq "$key" "$resets" || fail "$key is absent from reset handling"
done

grep -Fq 'case 5: return ["Общие", "График CPU", "Top Apps"]' "$settings_ui" || fail "Top Apps subtab is missing"
grep -Fq 'text: "Показывать заголовки CPU и памяти"' "$settings_section" || fail "headers setting is missing"
grep -Fq 'text: "Показывать полосы нагрузки"' "$settings_section" || fail "bars setting is missing"
grep -Fq 'onToggled: { Config.topAppsShowHeaders = checked; settings.save() }' "$settings_section" || fail "headers toggle does not save"
grep -Fq 'onToggled: { Config.topAppsShowBars = checked; settings.save() }' "$settings_section" || fail "bars toggle does not save"
grep -Fq 'height: Config.topAppsShowHeaders ? 12 : 0' "$ui" || fail "header row does not collapse when disabled"
grep -Fq 'visible: Config.topAppsShowBars' "$ui" || fail "bar rendering is not controlled by its setting"
grep -Fq 'width: Config.topAppsShowBars ? 98 : Math.max(40, parent.width - root.valueColumnWidth(sectionFrame.section.entries) - 2 * appRow.spacing)' "$ui" || fail "process name does not expand when bars are hidden"
grep -Fq 'width: Config.topAppsShowBars ? Math.max(0, parent.width - 98 - 5 - root.valueColumnWidth(sectionFrame.section.entries) - 5) : 0' "$ui" || fail "bar placeholder still consumes width when bars are hidden"
grep -Fq 'moduleName === "topApps"' "$resets" || fail "Top Apps module profile reset branch is missing"
grep -Fq '"topAppsShowHeaders", "topAppsShowBars"' "$resets" || fail "CPU/RAM reset does not restore Top Apps display settings"

echo "Top Apps display settings: OK"
