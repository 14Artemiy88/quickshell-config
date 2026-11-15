#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FIELD="$ROOT/components/settings/primitives/SettingsFontField.qml"
SECTION="$ROOT/components/settings/sections/SettingsNetworkSection.qml"
for file in "$FIELD" "$SECTION"; do test -f "$file"; done

# The reusable font primitive is a text field with a dedicated system-font reset.
grep -Fq 'SettingsInputField {' "$FIELD"
grep -Fq 'SettingsResetButton {' "$FIELD"
grep -Fq 'placeholderText: root.placeholderText' "$FIELD"
grep -Fq 'property string placeholderText: "Системный шрифт"' "$FIELD"
grep -Fq 'actionAvailable: root.normalizedFamily(root.value) !== ""' "$FIELD"
grep -Fq 'onClicked: root.commit("")' "$FIELD"
grep -Fq 'targetObject[root.targetProperty] = family' "$FIELD"
grep -Fq 'root.settingsObject.save()' "$FIELD"
grep -Fq '.slice(0, 128)' "$FIELD"

# Network uses the primitive, not a one-off FontDialog or duplicated button row.
grep -Fq 'SettingsFontField {' "$SECTION"
grep -Fq 'value: Config.networkFont' "$SECTION"
grep -Fq 'targetProperty: "networkFont"' "$SECTION"
grep -Fq 'settingsObject: root.settings' "$SECTION"
grep -Fq 'saveOnEdit: true' "$SECTION"
! grep -Eq 'FontDialog|networkFontDialog' "$SECTION"

echo 'Shared settings font-field primitive and Network integration: OK'
