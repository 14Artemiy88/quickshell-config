#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
export HOME="$work/home"
export XDG_CONFIG_HOME="$HOME/config" XDG_DATA_HOME="$HOME/share" XDG_STATE_HOME="$HOME/state" XDG_CACHE_HOME="$HOME/cache"
export XDG_RUNTIME_DIR="$work/runtime"
mkdir -p "$HOME" "$XDG_RUNTIME_DIR/timer" "$work/bin"
source "$ROOT/scripts/timer.d/common.sh"
source "$ROOT/scripts/timer.d/daemon.sh"
fail() { printf 'Timer daemon inline JSON array: FAIL: %s\n' "$1" >&2; exit 1; }

# Empty and populated serialization should match jq's prior compact-array output.
empty="$(timer_entries_to_json)"
[[ "$empty" == '[]' ]] || fail "empty array mismatch: $empty"
records=(
  '{"file":"/tmp/a","comment":"comma, quote: \"yes\"","timer":"01:02","color":"#abcdef","sign":"","time_passed":"00:10","ding":0}'
  '{"file":"/tmp/b","comment":"line\nnext 🎵","timer":"PAUSED","color":"#123456","sign":" + ","time_passed":"04:05","ding":1}'
)
actual="$(timer_entries_to_json "${records[@]}")"
expected="$(printf '%s\n' "${records[@]}" | jq -s -c .)"
[[ "$actual" == "$expected" ]] || fail "serialized array differs from compact jq output"
jq -e 'type == "array" and length == 2 and .[0].comment == "comma, quote: \"yes\"" and .[1].comment == "line\nnext 🎵"' <<< "$actual" >/dev/null || fail 'serialized records are not equivalent JSON'

# Run the real daemon for three cycles with one active timer. Count any jq
# invocation from the daemon; validation below uses the real jq by absolute path.
real_jq="$(command -v jq)"
real_sleep="$(command -v sleep)"
export TIMER_TEST_REAL_JQ="$real_jq" TIMER_TEST_REAL_SLEEP="$real_sleep"
export TIMER_TEST_JQ_LOG="$work/jq.log" TIMER_TEST_SLEEP_COUNT="$work/sleep-count"
export TIMER_TEST_TIMER_ROOT="$XDG_RUNTIME_DIR/timer"
cat > "$work/bin/jq" <<'WRAPPER'
#!/bin/sh
printf 'jq\n' >> "$TIMER_TEST_JQ_LOG"
exec "$TIMER_TEST_REAL_JQ" "$@"
WRAPPER
cat > "$work/bin/sleep" <<'WRAPPER'
#!/bin/sh
count=0
if [ -f "$TIMER_TEST_SLEEP_COUNT" ]; then IFS= read -r count < "$TIMER_TEST_SLEEP_COUNT" || count=0; fi
count=$((count + 1))
printf '%s\n' "$count" > "$TIMER_TEST_SLEEP_COUNT"
if [ "$count" -ge 3 ]; then kill -TERM "$PPID" 2>/dev/null || true; fi
exit 0
WRAPPER
chmod +x "$work/bin/jq" "$work/bin/sleep"
now="${EPOCHSECONDS:-$(date +%s)}"
printf '60 %s 0 aabbcc 0 focused-test, with comma\n' "$((now + 3600))" > "$TIMER_TEST_TIMER_ROOT/active-timer"
rm -f "$TIMER_TEST_JQ_LOG" "$TIMER_TEST_SLEEP_COUNT"
PATH="$work/bin:$PATH" bash -c 'source "$1/scripts/timer.d/common.sh"; source "$1/scripts/timer.d/daemon.sh"; run_daemon' _ "$ROOT" > "$work/daemon-output.log" 2>&1 &
pid=$!
for ((i=0; i<200; i++)); do
    [[ -f "$TIMER_TEST_SLEEP_COUNT" ]] && [[ "$(<"$TIMER_TEST_SLEEP_COUNT")" -ge 3 ]] && break
    "$real_sleep" 0.02
    kill -0 "$pid" 2>/dev/null || break
done
wait "$pid" 2>/dev/null || true
[[ -f "$TIMER_TEST_SLEEP_COUNT" && "$(<"$TIMER_TEST_SLEEP_COUNT")" -ge 3 ]] || fail 'daemon did not complete three cycles'
[[ ! -s "$TIMER_TEST_JQ_LOG" ]] || fail 'daemon launched jq while serializing a non-empty timer array'
[[ "$(wc -l < "$work/daemon-output.log")" -ge 3 ]] || fail 'daemon did not emit three cycles'
while IFS= read -r line; do
    "$real_jq" -e 'type == "array" and length == 1 and .[0].comment == "focused-test, with comma"' <<< "$line" >/dev/null || fail "daemon output invalid: $line"
done < "$work/daemon-output.log"

if grep -Fq 'printf '\''%s\\n'\'' "${timers[@]}" | jq -s -c .' "$ROOT/scripts/timer.d/daemon.sh"; then
    fail 'old jq array pipeline remains'
fi
grep -Fq 'timer_entries_to_json "${timers[@]}"' "$ROOT/scripts/timer.d/daemon.sh" || fail 'daemon does not use inline array serializer'
echo 'Timer daemon inline JSON array serialization: OK'
