#!/usr/bin/env bash
set -euo pipefail
file="$(dirname "$0")/../components/settings/SettingsWidget.qml"
host="$(dirname "$0")/../components/settings/SettingsPageHost.qml"
navigation="$(dirname "$0")/../components/settings/SettingsNavigationController.qml"
grep -Fq 'function settingsTabLabelForId(id)' "$file"
grep -Fq 'readonly property string currentPageTitle:' "$file"
grep -Fq 'return (main + (sub ? " · " + sub : "")).toLocaleUpperCase()' "$navigation"
grep -Fq 'text: root.host ? root.host.currentPageTitle : ""' "$host"
# Keep the generic label only for the window title; the content heading is contextual.
count=$(grep -Fc 'text: "НАСТРОЙКИ"' "$file")
[[ "$count" -eq 1 ]]
echo 'contextual settings heading: OK'
