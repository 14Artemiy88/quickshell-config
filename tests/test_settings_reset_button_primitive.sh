#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RESET="$ROOT/components/settings/primitives/SettingsResetButton.qml"
BUTTON="$ROOT/components/settings/primitives/SettingsButton.qml"
WIDGET="$ROOT/components/settings/SettingsWidget.qml"
for file in "$RESET" "$BUTTON" "$WIDGET"; do test -f "$file"; done

grep -Fq 'SettingsButton {' "$RESET" || { echo 'Reset button does not use the standard SettingsButton primitive' >&2; exit 1; }
grep -Fq 'readonly property bool hovered: button.hovered' "$RESET" || { echo 'Reset button hover state is not connected to SettingsButton' >&2; exit 1; }
grep -Fq 'fillOnHover: root.fillOnHover' "$RESET" || { echo 'Reset button does not delegate standard hover fill behavior' >&2; exit 1; }
grep -Fq 'borderOnHover: root.borderOnHover' "$RESET" || { echo 'Reset button does not delegate standard button border styling' >&2; exit 1; }
grep -Fq 'tooltip: root.tooltip' "$RESET" || { echo 'Tooltip was not delegated to SettingsButton' >&2; exit 1; }
grep -Fq 'disabledBorderColor: root.emphasized ? "#ff593d3d" : Config.baseColor' "$RESET" || { echo 'Disabled destructive button must use a muted red border' >&2; exit 1; }
grep -Fq 'disabledTextColor: root.emphasized ? "#ff9999" : Config.textMuted' "$RESET" || { echo 'Disabled destructive button text must use the muted idle red shade' >&2; exit 1; }
grep -Fq '(root.hovered ? "#ff6666" : "#ff9999")' "$RESET" || { echo 'Destructive button must use #ff9999 idle and #ff6666 hover' >&2; exit 1; }
grep -Fq 'property bool fontBold: true' "$RESET" || { echo 'Reset arrow should stay bold regardless of hover state' >&2; exit 1; }
if grep -Eq 'MouseArea|ToolTip|Rectangle[[:space:]]*\{' "$RESET"; then
    echo 'Reset button duplicates rendering or hover interaction already owned by HoverButtonSurface' >&2; exit 1
fi
grep -Fq 'spacing: 16' "$WIDGET" || { echo 'Settings sidebar/content gutter was not increased to 16 px' >&2; exit 1; }
grep -Fq 'width: parent.width - mainSettingsTabs.width - 16' "$WIDGET" || { echo 'Settings content width does not account for its wider sidebar gutter' >&2; exit 1; }
python3 - "$RESET" <<'PY'
from pathlib import Path
import sys
s=Path(sys.argv[1]).read_text()
for token in ['SettingsButton {','onClicked: root.clicked()','root.clicked()','property bool fillOnHover: false','emphasized: root.emphasized && (!root.emphasizedHoverOnly || root.hovered)','disabledBorderColor: root.emphasized ? "#ff593d3d" : Config.baseColor']:
    if token not in s: raise SystemExit('missing reset button contract: '+token)
print('Reset button uses border-only hover styling and settings sidebar spacing: OK')
PY
