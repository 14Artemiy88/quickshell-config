#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT
export HOME="$TMP_ROOT/home"
export XDG_CONFIG_HOME="$HOME/config" XDG_DATA_HOME="$HOME/share" XDG_STATE_HOME="$HOME/state" XDG_CACHE_HOME="$HOME/cache"
export XDG_RUNTIME_DIR="$TMP_ROOT/runtime"
mkdir -p "$HOME" "$XDG_RUNTIME_DIR"

source "$ROOT/scripts/env"
source "$ROOT/scripts/timer.d/common.sh"
source "$ROOT/scripts/timer.d/actions.sh"
source "$ROOT/scripts/timer.d/daemon.sh"
timer_ensure_dirs
fail() { printf 'timer interval reset test failed: %s\n' "$1" >&2; exit 1; }

read_field() {
    local field="$1" json="$2"
    if command -v jq >/dev/null 2>&1; then
        jq -r ".$field" <<< "$json"
    else
        sed -n "s/.*\\\"$field\\\":\\\"\\?\\([^,\\\"]*\\).*/\\1/p" <<< "$json"
    fi
}

# Active timer: 10-minute interval, 2 minutes already elapsed. Editing it to
# 15 minutes starts a fresh 15-minute countdown, while the overall counter
# keeps the previous 2 minutes.
now=$(date '+%s')
file="$TIMER_DIR/active"
printf '10 %s 0 aabbcc 0 active\n' "$((now + 8 * 60))" > "$file"
"$ROOT/scripts/timer" set_duration "$file" 15 || fail 'active duration update failed'
read -r total end ding color paused comment < "$file"
[[ "$total" == 15 ]] || fail "active duration should be 15, got $total"
[[ "$ding" == 0 && "$paused" == 0 ]] || fail 'active interval was not re-armed'
(( end > 0 )) || fail 'active countdown end timestamp is invalid'
restart_started_at=$((end - total * 60))
active_offset=$(cat "$TIMER_DIR/.elapsed-active")
[[ "$active_offset" =~ ^12[0-2]$ ]] || fail 'previous 2 minutes were not folded into cumulative elapsed state'
expected_active_elapsed=$(format_time "$active_offset")
json=$(timer_process_entry "$file" "$restart_started_at")
[[ "$(read_field time_passed "$json")" == "$expected_active_elapsed" ]] || fail "overall elapsed display should preserve $expected_active_elapsed at interval restart: $json"
[[ "$(read_field timer "$json")" == '15:00' ]] || fail "current countdown should restart at 15:00: $json"

# As the new interval runs, the global elapsed counter continues from the
# preserved offset instead of returning to zero. Use a virtual timestamp
# relative to the interval start so wall-clock scheduling cannot race this test.
json=$(timer_process_entry "$file" "$((restart_started_at + 60))")
expected_active_plus_minute=$(format_time "$((active_offset + 60))")
[[ "$(read_field time_passed "$json")" == "$expected_active_plus_minute" ]] || fail "overall elapsed counter did not continue after reset: $json"

# Paused timers retain their frozen accumulated time and restart the interval
# relative to paused_at, not the wall clock.
paused_at=$(date '+%s')
printf '10 %s 0 aabbcc %s paused\n' "$((paused_at + 8 * 60))" "$paused_at" > "$TIMER_DIR/paused"
"$ROOT/scripts/timer" set_duration "$TIMER_DIR/paused" 20 || fail 'paused duration update failed'
read -r total end ding color paused comment < "$TIMER_DIR/paused"
[[ "$total" == 20 && "$paused" == "$paused_at" ]] || fail 'paused timer duration or pause timestamp changed'
[[ "$end" == $((paused_at + 20 * 60)) ]] || fail 'paused countdown was not reset to the requested duration'
json=$(timer_process_entry "$TIMER_DIR/paused" "$((paused_at + 600))")
[[ "$(read_field time_passed "$json")" == '02:00' ]] || fail "paused global elapsed counter changed: $json"

# Completed timer: 5 minutes plus 2 minutes overdue. Editing to 10 minutes
# starts a fresh 10-minute interval while the overall counter remains 7:00.
now=$(date '+%s')
printf '5 %s 1 aabbcc 0 completed\n' "$((now - 2 * 60))" > "$TIMER_DIR/completed"
"$ROOT/scripts/timer" set_duration "$TIMER_DIR/completed" 10 || fail 'completed duration update failed'
read -r total end ding color paused comment < "$TIMER_DIR/completed"
[[ "$total" == 10 && "$ding" == 0 ]] || fail 'completed timer did not re-arm with new duration'
(( end > 0 )) || fail 'completed countdown end timestamp is invalid'
completed_restart_at=$((end - total * 60))
completed_offset=$(cat "$TIMER_DIR/.elapsed-completed")
[[ "$completed_offset" =~ ^42[0-2]$ ]] || fail 'completed timer did not preserve its previous 7 minutes'
json=$(timer_process_entry "$TIMER_DIR/completed" "$completed_restart_at")
[[ "$(read_field time_passed "$json")" == "$(format_time "$completed_offset")" ]] || fail "completed timer's overall counter did not preserve its accumulated value: $json"
[[ "$(read_field timer "$json")" == '10:00' ]] || fail "completed timer's new countdown is not 10:00: $json"

# The visible restart action has the same two-clock semantics: a new interval,
# but cumulative elapsed time continues.
now=$(date '+%s')
printf '5 %s 1 aabbcc 0 restart\n' "$((now - 2 * 60))" > "$TIMER_DIR/restart"
"$ROOT/scripts/timer" refresh "$TIMER_DIR/restart" || fail 'refresh action failed'
read -r restart_total restart_end _ < "$TIMER_DIR/restart"
restart_at=$((restart_end - restart_total * 60))
restart_offset=$(cat "$TIMER_DIR/.elapsed-restart")
json=$(timer_process_entry "$TIMER_DIR/restart" "$restart_at")
[[ "$(read_field timer "$json")" == '05:00' ]] || fail "refresh did not restart current timer: $json"
[[ "$(read_field time_passed "$json")" == "$(format_time "$restart_offset")" ]] || fail "refresh did not preserve cumulative elapsed time: $json"

# Legacy timer files without sidecars remain readable and start with offset 0.
legacy="$TIMER_DIR/legacy"
now=$(date '+%s')
printf '10 %s 0 aabbcc 0 legacy\n' "$((now + 8 * 60))" > "$legacy"
json=$(timer_process_entry "$legacy" "$now")
[[ "$(read_field time_passed "$json")" == '02:00' ]] || fail "legacy timer was not compatible: $json"

# Invalid requests must not modify either the timer record or its cumulative
# offset sidecar.
cp "$file" "$TMP_ROOT/before-invalid"
cp "$TIMER_DIR/.elapsed-active" "$TMP_ROOT/before-invalid-offset"
for invalid in 0 -1 abc 10081 123456; do
    if "$ROOT/scripts/timer" set_duration "$file" "$invalid" >/dev/null 2>&1; then
        fail "invalid duration was accepted: $invalid"
    fi
done
cmp -s "$TMP_ROOT/before-invalid" "$file" || fail 'invalid duration request modified timer state'
cmp -s "$TMP_ROOT/before-invalid-offset" "$TIMER_DIR/.elapsed-active" || fail 'invalid duration request modified cumulative elapsed state'

# Deleting a timer also deletes its hidden cumulative sidecar.
"$ROOT/scripts/timer" delete "$file" || fail 'timer deletion failed'
[[ ! -e "$file" && ! -e "$TIMER_DIR/.elapsed-active" ]] || fail 'timer deletion left a cumulative elapsed sidecar'

grep -Fq 'timer_with_lock timer_set_duration_locked' "$ROOT/scripts/timer.d/actions.sh" || fail 'duration edit is not serialized by the timer lock'
echo 'Timer duration edit restarts countdown and preserves cumulative elapsed time: OK'
