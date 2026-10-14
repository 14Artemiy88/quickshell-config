#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT
export HOME="$TMP_ROOT/home"
export XDG_CONFIG_HOME="$HOME/config"
export XDG_DATA_HOME="$HOME/share"
export XDG_STATE_HOME="$HOME/state"
export XDG_CACHE_HOME="$HOME/cache"
export XDG_RUNTIME_DIR="$TMP_ROOT/runtime"
mkdir -p "$HOME" "$XDG_RUNTIME_DIR"

source "$ROOT/scripts/env"
source "$ROOT/scripts/timer.d/common.sh"
source "$ROOT/scripts/timer.d/actions.sh"
source "$ROOT/scripts/timer.d/daemon.sh"
# Do not invoke desktop speech in the automated race test.
SAY_LOG="$TMP_ROOT/say.log"
export SAY_LOG
say() { printf 'ding\n' >> "$SAY_LOG"; }
timer_ensure_dirs

fail() { printf 'timer concurrency test failed: %s\n' "$1" >&2; exit 1; }

now=$(date '+%s')
end=$((now + 3600))
file="$TIMER_DIR/concurrent-timer"
printf '10 %s 0 aabbcc 0 initial\n' "$end" > "$file"

# Concurrent read-modify-write actions must not lose increments.
pids=()
for i in $(seq 1 32); do
    "$ROOT/scripts/timer" up "$file" >/dev/null &
    pids+=("$!")
done
for pid in "${pids[@]}"; do wait "$pid" || fail 'a parallel timer-up action failed'; done
IFS=' ' read -r total_time end_time ding color paused_at comment < "$file"
[[ "$total_time" == 42 ]] || fail "lost parallel increments: expected 42 minutes, got $total_time"
[[ "$end_time" == $((end + 32 * 60)) ]] || fail 'parallel extensions were lost'
[[ "$ding" == 0 && "$paused_at" == 0 ]] || fail 'timer state fields were corrupted'

# An even number of concurrent toggles must leave the timer unpaused.
pids=()
for i in $(seq 1 20); do
    "$ROOT/scripts/timer" toggle_pause "$file" >/dev/null &
    pids+=("$!")
done
for pid in "${pids[@]}"; do wait "$pid" || fail 'a parallel pause toggle failed'; done
IFS=' ' read -r total_time end_time ding color paused_at comment < "$file"
[[ "$paused_at" == 0 ]] || fail "parallel pause toggles left timer paused ($paused_at)"

# Concurrent comment writes must always leave one intact value, never a
# partially-written timer record. The last writer is deliberately unspecified.
pids=()
for i in $(seq 1 16); do
    "$ROOT/scripts/timer" set_comment "$file" "parallel-comment-$i" >/dev/null &
    pids+=("$!")
done
for pid in "${pids[@]}"; do wait "$pid" || fail 'a parallel comment edit failed'; done
IFS=' ' read -r total_time end_time ding color paused_at comment < "$file"
[[ "$comment" =~ ^parallel-comment-[0-9]+$ ]] || fail "comment record is corrupted: $comment"

# The daemon entry must read the latest state even when several writes happen
# in the same wall-clock second (the previous implementation cached by mtime).
json=$(timer_process_entry "$file" "$(date '+%s')")
jq -e --arg comment "$comment" '.comment == $comment and .ding == 0' <<< "$json" >/dev/null || fail 'daemon returned stale timer state'

# If an expiring timer is extended at the same time as the daemon processes it,
# serialization must leave the newer extension intact instead of restoring a
# stale expired record.
race_file="$TIMER_DIR/expiry-race"
race_now=$(date '+%s')
printf '5 %s 0 ccddee 0 race\n' "$((race_now - 15))" > "$race_file"
timer_process_entry "$race_file" "$race_now" >/dev/null & daemon_pid=$!
"$ROOT/scripts/timer" up "$race_file" >/dev/null & action_pid=$!
wait "$daemon_pid" || fail 'daemon expiry transition failed'
wait "$action_pid" || fail 'concurrent extension failed'
IFS=' ' read -r total_time end_time ding color paused_at comment < "$race_file"
[[ "$total_time" == 6 ]] || fail 'concurrent expiry overwrote the extended duration'
[[ "$end_time" -gt "$(date '+%s')" ]] || fail 'concurrent expiry restored an expired end time'
[[ "$ding" == 0 ]] || fail 'concurrent expiry restored a stale alarm state'

# A daemon expiry transition returns plain JSON and performs speech only after
# the lock was released. Exactly one pass changes ding from 0 to 1.
expired_file="$TIMER_DIR/expired-timer"
expired_now=$(date '+%s')
printf '3 %s 0 ddeeff 0 expired\n' "$((expired_now - 5))" > "$expired_file"
: > "$SAY_LOG"
expired_json=$(timer_process_entry "$expired_file" "$expired_now")
jq -e '.ding == 1 and .comment == "expired"' <<< "$expired_json" >/dev/null || fail 'daemon expiry result was not valid JSON'
[[ "$(wc -l < "$SAY_LOG")" == 1 ]] || fail 'expiry notification was not issued exactly once after state transition'

# The atomic writer uses only hidden temporary files; no partial records should
# leak into the timer directory or be mistaken for timer entries.
if find "$TIMER_DIR" -maxdepth 1 -type f -name '.timer-*' | grep -q .; then
    fail 'hidden timer temporary files were leaked'
fi

grep -Fq 'timer_with_lock timer_up_locked' "$ROOT/scripts/timer.d/actions.sh" || fail 'timer-up is not protected by the common lock'
grep -Fq 'timer_with_lock timer_process_entry_locked' "$ROOT/scripts/timer.d/daemon.sh" || fail 'daemon state transitions are not locked'
grep -Fq 'mktemp "$TIMER_DIR/.timer-write.XXXXXX"' "$ROOT/scripts/timer.d/common.sh" || fail 'atomic timer writer missing'
! grep -Fq 't_mtime' "$ROOT/scripts/timer.d/daemon.sh" || fail 'stale mtime cache remains in daemon'

echo 'Timer state concurrency: OK'
