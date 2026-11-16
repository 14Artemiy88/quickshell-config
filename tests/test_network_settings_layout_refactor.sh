#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SECTION="$ROOT/components/settings/sections/SettingsNetworkSection.qml"
WIDGET="$ROOT/components/NetworkStat.qml"
ROW="$ROOT/components/NetworkStatRow.qml"
CONFIG="$ROOT/Config.qml"
DEFAULTS="$ROOT/js/settings/SettingsDefaults.js"
APPLY="$ROOT/js/settings/SettingsApplySystemVisual.js"
PERSIST="$ROOT/js/settings/SettingsPersistence.js"
RESETS="$ROOT/js/settings/SettingsResets.js"
for file in "$SECTION" "$WIDGET" "$ROW" "$CONFIG" "$DEFAULTS" "$APPLY" "$PERSIST" "$RESETS"; do test -f "$file"; done

# The controls are grouped by purpose; the font family uses the shared text-field primitive.
! grep -Fq 'import QtQuick.Dialogs' "$SECTION"
! grep -Fq 'FontDialog {' "$SECTION"
grep -Fq 'SettingsFontField {' "$SECTION"
grep -Fq 'targetProperty: "networkFont"' "$SECTION"
grep -Fq 'heading: "Расположение"' "$SECTION"
grep -Fq 'heading: "Иконки"' "$SECTION"
grep -Fq 'heading: "Текст"' "$SECTION"
grep -Fq 'targetProperty: "networkSpacing"' "$SECTION"
grep -Fq 'targetProperty: "networkTopPadding"' "$SECTION"
grep -Fq 'property int networkTopPadding: 5' "$CONFIG"
grep -Fq 'networkTopPadding: 5' "$DEFAULTS"
grep -Fq 'targetProperty: "networkIconSize"' "$SECTION"
grep -Fq 'targetProperty: "networkIconLeftPadding"' "$SECTION"
grep -Fq 'targetProperty: "networkValueFontSize"' "$SECTION"

# Removed duplicate/shared controls; the icon slot is now computed by the row.
for file in "$SECTION" "$WIDGET" "$ROW" "$CONFIG" "$DEFAULTS" "$APPLY" "$PERSIST" "$RESETS"; do
    if grep -Eq 'network(RowHeight|RowSpacing|HorizontalPadding|IconColumnWidth)' "$file"; then
        echo "Legacy network layout setting remains in $file" >&2
        exit 1
    fi
done

# New keys have full default, apply, snapshot, and profile-reset coverage.
for key in networkSpacing networkTopPadding networkFont networkIconSize networkIconLeftPadding networkValueFontSize networkRightPadding; do
    grep -Fq "$key" "$CONFIG"
    grep -Fq "$key" "$DEFAULTS"
    grep -Fq "$key" "$APPLY"
    grep -Fq "$key" "$PERSIST"
    grep -Fq "$key" "$RESETS"
done

# One spacing value drives both the row's vertical breathing room and Column spacing.
grep -Fq 'anchors.topMargin: Config.networkTopPadding' "$WIDGET"
grep -Fq 'readonly property real networkStatRowGap:' "$WIDGET"
grep -Fq 'Config.networkSpacing * uploadRowMorph.geometryHeight / networkStatRowHeight' "$WIDGET"
grep -Fq 'height: Math.max(iconPixelSize, valuePixelSize) + Config.networkSpacing * 2' "$ROW"
! grep -Fq 'anchors.leftMargin: Config.networkHorizontalPadding' "$WIDGET"
! grep -Fq 'anchors.rightMargin: Config.networkHorizontalPadding' "$WIDGET"

echo 'Network settings layout refactor: OK'
