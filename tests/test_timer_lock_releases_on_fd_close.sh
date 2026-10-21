#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
export HOME="$WORK/home" XDG_CONFIG_HOME="$HOME/config" XDG_DATA_HOME="$HOME/share" XDG_STATE_HOME="$HOME/state" XDG_CACHE_HOME="$HOME/cache" XDG_RUNTIME_DIR="$WORK/runtime"
mkdir -p "$HOME" "$XDG_RUNTIME_DIR" "$WORK/bin"
REAL_FLOCK="$(command -v flock)"
[[ -x "$REAL_FLOCK" ]] || { echo 'flock is required for timer lock test' >&2; exit 1; }
export FLOCK_LOG="$WORK/flock.log"
: > "$FLOCK_LOG"
cat > "$WORK/bin/flock" <<'WRAPPER'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$FLOCK_LOG"
exec "$REAL_FLOCK" "$@"
WRAPPER
chmod +x "$WORK/bin/flock"
export REAL_FLOCK
export PATH="$WORK/bin:$PATH"

source "$ROOT/scripts/env"
source "$ROOT/scripts/timer.d/common.sh"
timer_noop_callback() { :; }
fail() { printf 'Timer lock fd close: FAIL: %s\n' "$1" >&2; exit 1; }

timer_ensure_dirs
FLOCK_LOG="$FLOCK_LOG" timer_with_lock timer_noop_callback
[[ "$(wc -l < "$FLOCK_LOG")" -eq 1 ]] || fail "expected one external flock invocation, got $(wc -l < "$FLOCK_LOG")"
grep -Eq '^-x [0-9]+$' "$FLOCK_LOG" || fail 'exclusive lock call missing or unexpected flock action used'

# Closing timer_with_lock's descriptor must release the lock, so a new open
# file description can immediately take a non-blocking lock on the same file.
exec {verify_fd}>"$TIMER_DIR/.state.lock"
"$REAL_FLOCK" -n "$verify_fd" || fail 'lock stayed held after timer_with_lock returned'
exec {verify_fd}>&-

grep -Fq 'exec {lock_fd}>&-' "$ROOT/scripts/timer.d/common.sh" || fail 'lock descriptor is not closed after callback'
! grep -Fq 'flock -u "$lock_fd"' "$ROOT/scripts/timer.d/common.sh" || fail 'redundant external unlock invocation remains'

echo 'Timer lock releases on fd close: OK'
