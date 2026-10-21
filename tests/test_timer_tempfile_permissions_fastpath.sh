#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
export HOME="$WORK/home" XDG_CONFIG_HOME="$HOME/config" XDG_DATA_HOME="$HOME/share" XDG_STATE_HOME="$HOME/state" XDG_CACHE_HOME="$HOME/cache" XDG_RUNTIME_DIR="$WORK/runtime"
mkdir -p "$HOME" "$XDG_RUNTIME_DIR"
source "$ROOT/scripts/env"
source "$ROOT/scripts/timer.d/common.sh"
timer_ensure_dirs
fail() { printf 'timer tempfile permissions test failed: %s\n' "$1" >&2; exit 1; }

# The common file writers must rely on mktemp's private mode, not chmod.
if grep -Eq 'chmod[[:space:]]+600[[:space:]]+"\$temp"' "$ROOT/scripts/timer.d/common.sh"; then
    fail 'timer writer still launches redundant chmod for mktemp output'
fi

timer_file="$TIMER_DIR/permission-writer-test"
total_time=5
end_time=2000000000
ding=0
color=aabbcc
paused_at=0
comment='permission check'
write_timer_file "$timer_file" || fail 'atomic timer write failed'
mode=$(stat -c '%a' -- "$timer_file")
[[ "$mode" == 600 ]] || fail "written timer mode is $mode, expected 600"

created_file="$TIMER_DIR/permission-create-test"
timer_create_file "$created_file" '5 2000000000 0 aabbcc 0 created' || fail 'atomic timer create failed'
mode=$(stat -c '%a' -- "$created_file")
[[ "$mode" == 600 ]] || fail "created timer mode is $mode, expected 600"

[[ ! -e "$TIMER_DIR/.timer-write."* ]] || fail 'temporary writer files leaked'
[[ ! -e "$TIMER_DIR/.timer-create."* ]] || fail 'temporary create files leaked'
printf 'Timer tempfile permissions fastpath: OK\n'
