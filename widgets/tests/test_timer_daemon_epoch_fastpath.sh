#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { printf 'Timer daemon EPOCHSECONDS fast path: FAIL: %s\n' "$1" >&2; exit 1; }
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
export HOME="$work/home"
export XDG_CONFIG_HOME="$HOME/config" XDG_DATA_HOME="$HOME/share" XDG_STATE_HOME="$HOME/state" XDG_CACHE_HOME="$HOME/cache"
export XDG_RUNTIME_DIR="$work/runtime"
mkdir -p "$HOME" "$XDG_RUNTIME_DIR" "$work/bin"
real_date="$(command -v date)"
real_sleep="$(command -v sleep)"
export TIMER_TEST_REAL_DATE="$real_date" TIMER_TEST_SLEEP_COUNT="$work/sleep-count"
cat > "$work/bin/date" <<'WRAPPER'
#!/bin/sh
printf 'date\n' >> "$TIMER_TEST_DATE_LOG"
exec "$TIMER_TEST_REAL_DATE" "$@"
WRAPPER
cat > "$work/bin/sleep" <<'WRAPPER'
#!/bin/sh
count=0
if [ -f "$TIMER_TEST_SLEEP_COUNT" ]; then IFS= read -r count < "$TIMER_TEST_SLEEP_COUNT" || count=0; fi
count=$((count + 1))
printf '%s\n' "$count" > "$TIMER_TEST_SLEEP_COUNT"
# End the child daemon after three output cycles so the test stays bounded.
if [ "$count" -ge 3 ]; then kill -TERM "$PPID" 2>/dev/null || true; fi
exit 0
WRAPPER
chmod +x "$work/bin/date" "$work/bin/sleep"
run_daemon_case() {
  local name="$1" unset_epoch="$2" date_log="$work/$1-date.log" out="$work/$1-output.log" pid i
  export TIMER_TEST_DATE_LOG="$date_log"
  rm -f "$date_log" "$TIMER_TEST_SLEEP_COUNT"
  if [[ "$unset_epoch" == 1 ]]; then
    PATH="$work/bin:$PATH" bash -c 'unset EPOCHSECONDS; source "$1/scripts/timer.d/common.sh"; source "$1/scripts/timer.d/daemon.sh"; run_daemon' _ "$ROOT" > "$out" 2>&1 &
  else
    PATH="$work/bin:$PATH" bash -c 'source "$1/scripts/timer.d/common.sh"; source "$1/scripts/timer.d/daemon.sh"; run_daemon' _ "$ROOT" > "$out" 2>&1 &
  fi
  pid=$!
  for ((i=0; i<100; i++)); do
    [[ -f "$TIMER_TEST_SLEEP_COUNT" ]] && { [[ "$(<"$TIMER_TEST_SLEEP_COUNT")" -ge 3 ]] && break; }
    "$real_sleep" 0.02
    kill -0 "$pid" 2>/dev/null || break
  done
  wait "$pid" 2>/dev/null || true
  [[ -f "$TIMER_TEST_SLEEP_COUNT" && "$(<"$TIMER_TEST_SLEEP_COUNT")" -ge 3 ]] || fail "$name daemon did not complete three cycles"
  [[ "$(grep -c '^\[\]$' "$out" || true)" -ge 3 ]] || fail "$name daemon did not emit valid empty timer arrays"
  if [[ -f "$date_log" ]]; then wc -l < "$date_log"; else printf '0\n'; fi
}

fast_date_calls="$(run_daemon_case native-epoch 0)"
[[ "$fast_date_calls" == 0 ]] || fail "native EPOCHSECONDS path launched date $fast_date_calls times"
fallback_date_calls="$(run_daemon_case legacy-fallback 1)"
[[ "$fallback_date_calls" -ge 3 ]] || fail "older-Bash fallback did not use date on each tick (calls=$fallback_date_calls)"

grep -Fq 'now=${EPOCHSECONDS:-}' "$ROOT/scripts/timer.d/daemon.sh" || fail 'daemon does not read EPOCHSECONDS'
grep -Fq 'now=$(date '\''+%s'\'')' "$ROOT/scripts/timer.d/daemon.sh" || fail 'older-Bash date fallback was removed'
echo 'Timer daemon EPOCHSECONDS fast path and date fallback: OK'
