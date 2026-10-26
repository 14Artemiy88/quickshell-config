#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUTTON="$ROOT/components/settings/primitives/SettingsButton.qml"
RESET="$ROOT/components/settings/primitives/SettingsResetButton.qml"
WIDGET="$ROOT/components/settings/SettingsWidget.qml"
SECTION="$ROOT/components/settings/sections/SettingsWindowSection.qml"
grep -Fq 'visible: enabled' "$BUTTON" || { echo 'Disabled standard buttons must be hidden' >&2; exit 1; }
grep -Fq 'visible: enabled' "$RESET" || { echo 'Disabled reset buttons must be hidden' >&2; exit 1; }
grep -Fq 'function syncProfileComboToActiveProfile()' "$SECTION" || { echo 'Profile selector lacks active-profile synchronization' >&2; exit 1; }
grep -Fq 'function onProfilesRevisionChanged() { Qt.callLater(settingsWindowColumn.syncProfileComboToActiveProfile) }' "$SECTION" || { echo 'Profile selector does not resync after profile list changes' >&2; exit 1; }
grep -Fq 'function onActiveProfileChanged() { Qt.callLater(settingsWindowColumn.syncProfileComboToActiveProfile) }' "$SECTION" || { echo 'Profile selector does not resync after active profile changes' >&2; exit 1; }
grep -Fq 'text: settings.activeProfile ? "Активный профиль: " + settings.activeProfile : "Активный профиль: по умолчанию"' "$SECTION" || { echo 'Profile groupbox heading does not show the active profile' >&2; exit 1; }
if grep -Fq 'Текущий профиль:' "$SECTION"; then echo 'Redundant current-profile text remains' >&2; exit 1; fi
echo 'Disabled buttons are hidden and active profile is reflected in the groupbox: OK'
