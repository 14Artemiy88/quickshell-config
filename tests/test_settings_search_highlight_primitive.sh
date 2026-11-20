#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "Settings search highlight primitive: FAIL: $*" >&2; exit 1; }
PRIMITIVE="$ROOT/components/settings/primitives/SettingsSearchHighlight.qml"
[[ -f "$PRIMITIVE" ]] || fail 'shared highlight primitive is missing'
for property in 'property bool highlighted' 'property bool currentMatch' 'property string matchHint' 'property real cornerRadius' 'property int overlayZ'; do
    grep -Fq "$property" "$PRIMITIVE" || fail "missing property: $property"
done
grep -Fq 'Config.settingsSearchHighlightBorderWidth' "$PRIMITIVE" || fail 'configured border width is not used'
grep -Fq 'Config.settingsSearchHighlightColor' "$PRIMITIVE" || fail 'configured highlight color is not used'
grep -Fq 'matchHover.hovered' "$PRIMITIVE" || fail 'hover tooltip is not wired'
for primitive in SettingsCheckBox SettingsNumberField SettingsColorField SettingsFontField SettingsGroup; do
    grep -Fq 'SettingsSearchHighlight {' "$ROOT/components/settings/primitives/$primitive.qml" || fail "$primitive does not use shared overlay"
done
for primitive in SettingsInputField SettingsComboBox; do
    grep -Fq 'Config.settingsSearchHighlightBorderWidth' "$ROOT/components/settings/primitives/$primitive.qml" || fail "$primitive lost its integrated border highlight"
done
printf 'Settings search highlight primitive: OK\n'
