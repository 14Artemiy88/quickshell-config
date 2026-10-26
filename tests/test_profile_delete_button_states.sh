#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RESET="$ROOT/components/settings/primitives/SettingsResetButton.qml"
SECTION="$ROOT/components/settings/sections/SettingsWindowSection.qml"
grep -Fq 'property string iconText: ""' "$RESET" || { echo 'Reset primitive lacks icon-only glyph support' >&2; exit 1; }
grep -Fq 'iconText: root.iconText' "$RESET" || { echo 'Reset primitive does not pass icon glyph to SettingsButton' >&2; exit 1; }
grep -Fq 'iconFontFamily: root.iconFontFamily' "$RESET" || { echo 'Reset primitive does not pass Nerd Font family to SettingsButton' >&2; exit 1; }
grep -Fq 'accentColor: root.emphasized' "$RESET" || { echo 'Destructive icon and border must share state colors' >&2; exit 1; }
grep -Fq '(root.hovered ? "#ff6666" : "#ff9999")' "$RESET" || { echo 'Destructive color must be #ff9999 idle and #ff6666 on hover' >&2; exit 1; }
grep -Fq 'outlineColor: root.emphasized ? (root.hovered ? "#ff6666" : "#ff9999") : Config.baseColor' "$RESET" || { echo 'Destructive border must match icon colors in both states' >&2; exit 1; }
grep -Fq 'iconText: "\uf1f8"' "$SECTION" || { echo 'Profile delete button must use the Nerd Font trash icon' >&2; exit 1; }
grep -Fq 'emphasizedHoverOnly: true' "$SECTION" || { echo 'Profile delete button emphasis should be hover-only' >&2; exit 1; }
grep -Fq 'emphasizedColor: "#ff9999"' "$SECTION" || { echo 'Profile delete icon should be muted when not hovered' >&2; exit 1; }
grep -Fq 'visible: enabled && actionAvailable' "$RESET" || { echo 'Unavailable reset/delete actions should be hidden' >&2; exit 1; }
grep -Fq 'onClicked: root.clicked()' "$RESET" || { echo 'Reset button should delegate clicks without permanently disabling itself' >&2; exit 1; }
grep -Fq 'visible: enabled' "$ROOT/components/settings/primitives/SettingsButton.qml" || { echo 'Disabled standard buttons should be hidden' >&2; exit 1; }
echo 'Profile delete button uses #ff9999 idle and #ff6666 hover colors: OK'
