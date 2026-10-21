#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WIDGET="$ROOT/components/TimerWidget.qml"
SCRIPT="$ROOT/scripts/timer"
ACTIONS="$ROOT/scripts/timer.d/actions.sh"
grep -Fq 'const step = (wheel.modifiers & Qt.ShiftModifier) ? 10 : 1' "$WIDGET" || { echo 'Shift-wheel does not select ten-minute step' >&2; exit 1; }
grep -Fq 'timerData.file, String(step)' "$WIDGET" || { echo 'Timer wheel step is not passed to the action script' >&2; exit 1; }
grep -Fq 'wheel.accepted = true' "$WIDGET" || { echo 'Timer wheel event is not accepted' >&2; exit 1; }
grep -Fq 'up)            timer_up "$2" "${3:-1}";;' "$SCRIPT" || { echo 'Timer up does not accept an optional step' >&2; exit 1; }
grep -Fq 'down)          timer_down "$2" "${3:-1}";;' "$SCRIPT" || { echo 'Timer down does not accept an optional step' >&2; exit 1; }
grep -Fq 'end_time=$((end_time + 60 * step))' "$ACTIONS" || { echo 'Timer up does not multiply the step correctly' >&2; exit 1; }
grep -Fq 'end_time=$((end_time - 60 * step))' "$ACTIONS" || { echo 'Timer down does not multiply the step correctly' >&2; exit 1; }

TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT
export HOME="$TMP_ROOT/home"
export XDG_CONFIG_HOME="$HOME/config" XDG_DATA_HOME="$HOME/share" XDG_STATE_HOME="$HOME/state" XDG_CACHE_HOME="$HOME/cache"
export XDG_RUNTIME_DIR="$TMP_ROOT/runtime"
mkdir -p "$HOME" "$XDG_RUNTIME_DIR"
source "$ROOT/scripts/env"
source "$ROOT/scripts/timer.d/common.sh"
timer_ensure_dirs
now=$(date '+%s')
start_end=$((now + 3600))
file="$TIMER_DIR/shift-wheel-test"
printf '10 %s 0 aabbcc 0 test\n' "$start_end" > "$file"
"$SCRIPT" up "$file" 10
read -r total end ding color paused comment < "$file"
[[ "$total" == 20 ]] || { echo "Shift-up total should be 20 minutes, got $total" >&2; exit 1; }
[[ "$end" == $((start_end + 600)) ]] || { echo 'Shift-up should extend the end time by ten minutes' >&2; exit 1; }
"$SCRIPT" down "$file" 10
read -r total end ding color paused comment < "$file"
[[ "$total" == 10 ]] || { echo "Shift-down total should return to 10 minutes, got $total" >&2; exit 1; }
[[ "$end" == "$start_end" ]] || { echo 'Shift-down should subtract ten minutes from the end time' >&2; exit 1; }
"$SCRIPT" up "$file" 0
read -r total end ding color paused comment < "$file"
[[ "$total" == 11 ]] || { echo 'Invalid zero step should safely fall back to one minute' >&2; exit 1; }
echo 'Timer Shift-wheel adjusts by ten minutes with locked, validated updates: OK'
