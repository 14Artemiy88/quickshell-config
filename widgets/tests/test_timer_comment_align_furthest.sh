#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "Timer furthest alignment: FAIL: $*" >&2; exit 1; }
qml="$ROOT/components/TimerWidget.qml"
settings="$ROOT/components/settings/sections/SettingsTimersSection.qml"
config="$ROOT/Config.qml"
defaults="$ROOT/js/settings/SettingsDefaults.js"
persist="$ROOT/js/settings/SettingsPersistence.js"
apply="$ROOT/js/settings/SettingsApplyTimerPlayer.js"
resets="$ROOT/js/settings/SettingsResets.js"

# The option is opt-in to preserve the current per-row adaptive spacing by default.
grep -Fq 'property bool timerCommentAlignFurthest: false' "$config" || fail 'Config default missing'
grep -Fq 'timerCommentAlignFurthest: false' "$defaults" || fail 'settings default missing'
# Save/load/profile reset must carry the new field.
grep -Fq 'timerCommentAlignFurthest: config.timerCommentAlignFurthest' "$persist" || fail 'snapshot persistence missing'
grep -Fq 'o.timerCommentAlignFurthest !== undefined' "$apply" || fail 'settings restore missing'
grep -Fq '"timerCommentAlignFurthest"' "$resets" || fail 'timer reset/profile support missing'
# The UI option controls whether each row uses the measured maximum width.
grep -Fq 'text: "Выравнивать комментарии по самому длинному таймеру"' "$settings" || fail 'settings checkbox missing'
grep -Fq 'checked: Config.timerCommentAlignFurthest' "$settings" || fail 'checkbox not bound'
grep -Fq 'root.widestTimerTextWidth' "$qml" || fail 'common widest countdown width missing'
grep -Fq 'id: timerWidthMeasurer' "$qml" || fail 'countdown measurement repeater missing'
grep -Fq 'Config.timerCommentAlignFurthest && root.widestTimerTextWidth > 0' "$qml" || fail 'optional aligned width not wired into timer display'
# The normal mode remains dynamically sized per countdown.
grep -Fq ': Math.ceil(textMetrics.advanceWidth) + 2' "$qml" || fail 'adaptive default width path missing'

echo 'Timer furthest alignment: OK'
