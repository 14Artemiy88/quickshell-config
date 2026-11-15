#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="$ROOT/Config.qml"
DEFAULTS="$ROOT/js/settings/SettingsDefaults.js"
APPLY="$ROOT/js/settings/SettingsApplySystemVisual.js"
PERSIST="$ROOT/js/settings/SettingsPersistence.js"
RESETS="$ROOT/js/settings/SettingsResets.js"
SHELL="$ROOT/shell.qml"
WIDGET="$ROOT/components/NetworkStat.qml"
SECTION="$ROOT/components/settings/sections/SettingsNetworkSection.qml"
SCOPE="$ROOT/components/settings/SettingsWidget.qml"
for file in "$CONFIG" "$DEFAULTS" "$APPLY" "$PERSIST" "$RESETS" "$SHELL" "$WIDGET" "$SECTION" "$SCOPE"; do
    test -f "$file"
done

# The NetworkStat click target is the entry point to the Networks selector.
grep -Fq 'acceptedButtons: Qt.LeftButton' "$WIDGET"
grep -Fq 'onClicked: root.networksRequested()' "$WIDGET"
grep -Fq 'signal networksRequested()' "$WIDGET"
grep -Fq 'onNetworksRequested:' "$SHELL"

# Popup state is controlled independently from the always-visible/manual mode.
grep -Fq 'property bool networksVisible: false' "$SHELL"
grep -Fq 'target: "networks"' "$SHELL"
grep -Fq 'function toggle(): void' "$SHELL"
grep -Fq 'function show(): void' "$SHELL"
grep -Fq 'function hide(): void' "$SHELL"
grep -Fq 'manageInputMask: true' "$SHELL"
grep -Fq 'backgroundBlurItem: networksVisibility.blurRegionItem' "$SHELL"
grep -Fq 'shown: Config.networksAlwaysVisible || shell.networksVisible || shell.layoutEditMode' "$SHELL"

# Always-visible mode is persisted, editable, and participates in reset/profile scopes.
grep -Fq 'property bool networksAlwaysVisible: false' "$CONFIG"
grep -Fq 'networksAlwaysVisible: false' "$DEFAULTS"
grep -Fq 'if (o.networksAlwaysVisible !== undefined) Config.networksAlwaysVisible = !!o.networksAlwaysVisible' "$APPLY"
grep -Fq 'networksAlwaysVisible: config.networksAlwaysVisible' "$PERSIST"
grep -Fq '"networksAlwaysVisible"' "$RESETS"
grep -Fq 'changeKeys: ({ keys: ["networksAlwaysVisible"] })' "$SECTION"
grep -Fq 'text: "Показывать Networks всегда"' "$SECTION"
grep -Fq 'checked: Config.networksAlwaysVisible' "$SECTION"
grep -Fq 'function onNetworksAlwaysVisibleChanged()' "$SECTION"
grep -Fq 'networksAlwaysVisible' "$SCOPE"

# Ensure module-disable cleanup and the always-visible transition cannot leave stale popup state.
grep -Fq 'function onNetworksChanged()' "$SHELL"
grep -Fq 'function onNetworksAlwaysVisibleChanged()' "$SHELL"

echo 'Networks selector popup link and manual visibility setting: OK'
