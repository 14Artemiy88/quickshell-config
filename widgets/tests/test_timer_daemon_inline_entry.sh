#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
export HOME="$WORK/home" XDG_CONFIG_HOME="$HOME/config" XDG_DATA_HOME="$HOME/share" XDG_STATE_HOME="$HOME/state" XDG_CACHE_HOME="$HOME/cache" XDG_RUNTIME_DIR="$WORK/runtime"
mkdir -p "$HOME" "$XDG_RUNTIME_DIR"
source "$ROOT/scripts/env"
source "$ROOT/scripts/timer.d/common.sh"
source "$ROOT/scripts/timer.d/actions.sh"
source "$ROOT/scripts/timer.d/daemon.sh"
SAY_LOG="$WORK/say.log"
say() { printf 'ding\n' >> "$SAY_LOG"; }
timer_ensure_dirs
fail() { printf 'Timer daemon inline entry: FAIL: %s\n' "$1" >&2; exit 1; }

now="${EPOCHSECONDS:-$(date '+%s')}"
file="$TIMER_DIR/inline-entry"
printf '20 %s 0 a1b2c3 0 comment with \\"quotes\\" and comma, unicode 🎵\n' "$((now + 1200))" > "$file"

entry='__unset__'
timer_process_entry_into entry "$file" "$now" || fail 'direct entry assignment returned nonzero'
[[ "$entry" != '__unset__' && -n "$entry" ]] || fail 'direct entry assignment did not populate caller variable'
jq -e --arg file "$file" '.file == $file and .comment == "comment with \\\"quotes\\\" and comma, unicode 🎵" and .ding == 0' <<< "$entry" >/dev/null || fail 'direct entry is not valid/equivalent JSON'
stdout_entry="$(timer_process_entry "$file" "$now")"
[[ "$stdout_entry" == "$entry" ]] || fail 'stdout compatibility wrapper differs from direct assignment'

# A real expired timer still performs exactly one expiration transition and
# defers speech until the lock has been released.
expired_file="$TIMER_DIR/expired"
printf '2 %s 0 aabbcc 0 expired\n' "$((now - 5))" > "$expired_file"
: > "$SAY_LOG"
expired_entry=''
timer_process_entry_into expired_entry "$expired_file" "$now" || fail 'expired entry handling returned nonzero'
jq -e '.ding == 1 and .comment == "expired"' <<< "$expired_entry" >/dev/null || fail 'expired entry JSON/state incorrect'
[[ "$(wc -l < "$SAY_LOG")" == 1 ]] || fail 'expiration notification was not emitted exactly once'

if grep -Fq 'data=$(timer_process_entry ' "$ROOT/scripts/timer.d/daemon.sh"; then
    fail 'daemon still captures each timer entry through command substitution'
fi
grep -Fq 'timer_process_entry_into data "$file" "$now"' "$ROOT/scripts/timer.d/daemon.sh" || fail 'daemon does not use direct entry assignment'
grep -Fq 'timer_with_lock timer_process_entry_locked' "$ROOT/scripts/timer.d/daemon.sh" || fail 'entry state transition is no longer protected by lock'
echo 'Timer daemon inline entry assignment: OK'
