#!/usr/bin/env bash
set -euo pipefail
file="$(dirname "$0")/../components/settings/SettingsWidget.qml"
grep -Fq 'readonly property var otherTabLabels:' "$file"
grep -Fq 'readonly property string currentOtherTabTitle:' "$file"
grep -Fq 'return (main + (sub ? " · " + sub : "")).toLocaleUpperCase()' "$file"
grep -Fq 'text: root.currentOtherTabTitle' "$file"
# Keep the generic label only for the window title; the content heading is contextual.
count=$(grep -Fc 'text: "НАСТРОЙКИ"' "$file")
[[ "$count" -eq 1 ]]
echo 'contextual settings heading: OK'
