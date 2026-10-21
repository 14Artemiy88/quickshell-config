#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
export HOME="$work/home"
export XDG_CONFIG_HOME="$HOME/config" XDG_DATA_HOME="$HOME/share" XDG_STATE_HOME="$HOME/state" XDG_CACHE_HOME="$HOME/cache"
export XDG_RUNTIME_DIR="$work/runtime"
mkdir -p "$HOME" "$XDG_RUNTIME_DIR" "$work/bin"
source "$ROOT/scripts/env"
source "$ROOT/scripts/timer.d/common.sh"
source "$ROOT/scripts/timer.d/daemon.sh"
real_flock="$(command -v flock)"
export TIMER_TEST_REAL_FLOCK="$real_flock" TIMER_TEST_FLOCK_LOG="$work/flock.log"
cat > "$work/bin/flock" <<'WRAPPER'
#!/bin/sh
printf 'flock\n' >> "$TIMER_TEST_FLOCK_LOG"
exec "$TIMER_TEST_REAL_FLOCK" "$@"
WRAPPER
chmod +x "$work/bin/flock"
PATH="$work/bin:$PATH"
export PATH
fail() { printf 'Timer batched snapshot lock: FAIL: %s\n' "$1" >&2; exit 1; }
timer_ensure_dirs
now="${EPOCHSECONDS:-$(date +%s)}"
files=()
for i in 1 2 3 4 5 6 7 8; do
    file="$TIMER_DIR/timer-$i"
    printf '30 %s 0 aabbcc 0 timer-%s\n' "$((now + 3600 + i))" "$i" > "$file"
    files+=("$file")
done

# Legacy behavior: each timer entry acquired its own flock subprocess.
: > "$TIMER_TEST_FLOCK_LOG"
for file in "${files[@]}"; do
    entry=''
    timer_process_entry_into entry "$file" "$now" || fail 'legacy single-entry helper failed'
done
old_locks="$(wc -l < "$TIMER_TEST_FLOCK_LOG")"
[[ "$old_locks" == 8 ]] || fail "expected 8 per-entry lock subprocesses, got $old_locks"

# New daemon tick: one lock protects the entire snapshot, including any expiry writes.
: > "$TIMER_TEST_FLOCK_LOG"
payload=''
expirations=-1
timer_with_lock timer_process_batch_locked payload expirations "$now" || fail 'batched snapshot failed'
new_locks="$(wc -l < "$TIMER_TEST_FLOCK_LOG")"
[[ "$new_locks" == 1 ]] || fail "expected 1 batched lock subprocess, got $new_locks"
[[ "$expirations" == 0 ]] || fail "unexpected expiration count: $expirations"
jq -e 'type == "array" and length == 8 and all(.[]; .ding == 0)' <<< "$payload" >/dev/null || fail 'batch JSON shape or timer state mismatch'

# Expiration still persists exactly once and reports the ding transition separately.
expired_file="$TIMER_DIR/expired"
printf '2 %s 0 ddeeff 0 batch-expired\n' "$((now - 5))" > "$expired_file"
: > "$TIMER_TEST_FLOCK_LOG"
timer_with_lock timer_process_batch_locked payload expirations "$now" || fail 'expired batch failed'
[[ "$expirations" == 1 ]] || fail "expected one first-time expiration, got $expirations"
jq -e --arg file "$expired_file" 'type == "array" and any(.[]; .file == $file and .ding == 1)' <<< "$payload" >/dev/null || fail 'expired timer missing from snapshot or ding not persisted'
IFS=' ' read -r total_time end_time ding color paused_at comment < "$expired_file"
[[ "$ding" == 1 ]] || fail 'expiration transition was not written to timer state'
timer_with_lock timer_process_batch_locked payload expirations "$now" || fail 'second expired batch failed'
[[ "$expirations" == 0 ]] || fail 'already-dinged timer generated a duplicate expiration'

# The speech loop is deliberately outside the single-lock call in the daemon.
awk '/timer_with_lock timer_process_batch_locked tick_payload tick_expirations/ { lock_line = NR }
     /say "\$MESSAGE"/ { say_line = NR }
     END { exit !(lock_line > 0 && say_line > lock_line) }' "$ROOT/scripts/timer.d/daemon.sh" || fail 'speech could execute before lock release'

echo 'Timer batched snapshot lock: OK (8 lock subprocesses -> 1; expiration emitted once)'
