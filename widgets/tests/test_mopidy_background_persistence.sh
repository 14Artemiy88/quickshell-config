#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# Keep this module-specific value JSON-safe across settings snapshots and profiles.
grep -Eq 'property string mopidyBackground: "#cc000000"' "$ROOT/Config.qml"
grep -Fq 'mopidyBackground: String(config.mopidyBackground)' "$ROOT/js/settings/SettingsPersistence.js"
grep -Fq 'if (o.mopidyBackground !== undefined)' "$ROOT/js/settings/SettingsApplyTimerPlayer.js"
grep -Fq 'targetProperty: "mopidyBackground"' "$ROOT/components/settings/sections/SettingsMopidySection.qml"
grep -Fq 'function onMopidyBackgroundChanged()' "$ROOT/components/settings/sections/SettingsMopidySection.qml"
grep -Fq 'root.settings.save()' "$ROOT/components/settings/sections/SettingsMopidySection.qml"
echo "Mopidy background persistence: OK"
