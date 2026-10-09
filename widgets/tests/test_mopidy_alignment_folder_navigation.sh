#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

grep -Fq 'property string mopidyQueueDurationAlignment: "right"' "$ROOT/Config.qml"
grep -Fq 'mopidyQueueDurationAlignment: "right"' "$ROOT/js/settings/SettingsDefaults.js"
grep -Fq 'mopidyQueueDurationAlignment: config.mopidyQueueDurationAlignment' "$ROOT/js/settings/SettingsPersistence.js"
grep -Fq 'queueDurationAlignment === "left" || queueDurationAlignment === "right"' "$ROOT/js/settings/SettingsApplyTimerPlayer.js"
grep -Fq '"mopidyQueueDurationAlignment"' "$ROOT/js/settings/SettingsResets.js"
grep -Fq 'horizontalAlignment: Config.mopidyQueueDurationAlignment === "left" ? Text.AlignLeft : Text.AlignRight' "$ROOT/components/Mopidy.qml"
grep -Fq 'enabled: !root.browseBusy' "$ROOT/components/Mopidy.qml"
grep -Fq 'font.bold: false' "$ROOT/components/Mopidy.qml"
echo 'Mopidy duration alignment and folder navigation: OK'
