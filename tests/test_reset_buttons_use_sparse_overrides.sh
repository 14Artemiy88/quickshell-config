#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SETTINGS="$ROOT/Settings.qml"
PERSISTENCE="$ROOT/js/settings/SettingsPersistence.js"
RESET="$ROOT/components/settings/primitives/SettingsResetButton.qml"
grep -Fq 'var overrides = root.resetOverrides || {}' "$SETTINGS"
grep -Fq 'property var resetOverrides: ({})' "$SETTINGS"
grep -Fq 'function updateResetOverridesCache(owner, overrides)' "$PERSISTENCE"
grep -Fq 'updateResetOverridesCache(owner, payload.profileOverrides)' "$PERSISTENCE"
if grep -Fq 'SettingsPersistence.payloadObject(root, Config).profileOverrides' "$SETTINGS"; then
  echo 'Reset-button binding still recomputes the complete persistence payload' >&2
  exit 1
fi
grep -Fq 'if (present(overrides, keys[i]) && hasLeaves(overrides[keys[i]])) return true' "$SETTINGS"
grep -Fq 'function payloadObject(owner, config)' "$PERSISTENCE"
grep -Fq 'profileOverrides: overrides' "$PERSISTENCE"
grep -Fq 'onClicked: root.clicked()' "$RESET"
if grep -Fq 'visible = false' "$RESET"; then
  echo 'Reset button still mutates visibility directly on click' >&2
  exit 1
fi
echo 'Reset button visibility follows sparse settings.json overrides, not click state: OK'
