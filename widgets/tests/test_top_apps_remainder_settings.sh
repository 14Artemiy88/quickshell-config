#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "Top Apps remainder settings: FAIL: $*" >&2; exit 1; }
config="$ROOT/Config.qml"
defaults="$ROOT/js/settings/SettingsDefaults.js"
apply="$ROOT/js/settings/SettingsApplySystemVisual.js"
persist="$ROOT/js/settings/SettingsPersistence.js"
resets="$ROOT/js/settings/SettingsResets.js"
ui="$ROOT/components/settings/sections/SettingsCpuRamSection.qml"
service="$ROOT/services/SystemMonitor.qml"
monitor="$ROOT/scripts/system_monitor"
collector="$ROOT/scripts/system_monitor.d/top_apps.sh"

for spec in 'topAppsShowSystemRemainder: bool' 'topAppsSystemRemainderLabel: string'; do
    key="${spec%%:*}"
    type="${spec#*: }"
    grep -Fq "property $type $key" "$config" || fail "$key Config property is missing"
    grep -Fq "$key:" "$defaults" || fail "$key default is missing"
    grep -Fq "$key: config.$key" "$persist" || fail "$key is not persisted"
    grep -Fq "$key" "$resets" || fail "$key is absent from profile reset handling"
done

grep -Fq 'topAppsShowSystemRemainder: true' "$defaults" || fail 'remainder should be enabled by default to preserve current behavior'
grep -Fq 'topAppsSystemRemainderLabel: "Система/прочее"' "$defaults" || fail 'default remainder label is missing'
grep -Fq 'if (o.topAppsShowSystemRemainder !== undefined) Config.topAppsShowSystemRemainder = !!o.topAppsShowSystemRemainder' "$apply" || fail 'remainder visibility is not restored'
grep -Fq 'Config.topAppsSystemRemainderLabel = remainderLabel || "Система/прочее"' "$apply" || fail 'label restore/sanitization fallback is missing'
grep -Fq 'text: "Показывать строку «Система/прочее»"' "$ui" || fail 'visibility checkbox is missing'
grep -Fq 'Config.topAppsShowSystemRemainder = checked; settings.save()' "$ui" || fail 'visibility checkbox does not persist'
grep -Fq 'text: "Название строки остатка"' "$ui" || fail 'custom label field is missing'
grep -Fq 'Config.topAppsSystemRemainderLabel = text.replace' "$ui" || fail 'custom label field does not sanitize and save'
grep -Fq 'Config.topAppsShowSystemRemainder ? "1" : "0"' "$service" || fail 'service does not forward visibility option'
grep -Fq 'Config.topAppsSystemRemainderLabel' "$service" || fail 'service does not forward custom label'
grep -Fq 'target: Config' "$service" || fail 'display settings changes are not observed by System Monitor'
grep -Fq 'get_top_apps "$WANT_TOP_APPS_CPU" "$WANT_TOP_APPS_RAM" "$WANT_TOP_APPS_SYSTEM_REMAINDER" "$TOP_APPS_SYSTEM_REMAINDER_LABEL"' "$monitor" || fail 'system_monitor does not forward remainder options'
grep -Fq 'aggregate_process_rows cpu 5' "$collector" || fail 'disabled remainder does not use the top five groups'
grep -Fq 'local show_remainder="${3:-1}" remainder_label="${4:-Система/прочее}"' "$collector" || fail 'legacy calls should preserve remainder default'

echo 'Top Apps remainder settings: OK'
