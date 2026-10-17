#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="$ROOT/scripts/timer"
fail() { printf 'Timer script-dir fast path: FAIL: %s\n' "$1" >&2; exit 1; }

if grep -Eq 'dirname[[:space:]]+.*\$0|dirname[[:space:]]+.*BASH_SOURCE' "$TARGET"; then
    fail 'external dirname remains in timer prologue'
fi
grep -Fq 'TIMER_SCRIPT_PATH="${BASH_SOURCE[0]}"' "$TARGET" || fail 'Bash source-path handling is missing'
grep -Fq 'source "$TIMER_SCRIPT_DIR/timer.d/daemon.sh"' "$TARGET" || fail 'daemon sibling source path is missing'

work="$(mktemp -d)"
trap 'rm -rf -- "$work"' EXIT
project="$work/Timer Project With Spaces"
mkdir -p "$project/scripts/timer.d" "$work/bin"
cp "$TARGET" "$project/scripts/timer"
cat > "$project/scripts/env" <<'STUB'
printf 'env\n' >> "$TEST_SOURCE_LOG"
STUB
cat > "$project/scripts/timer.d/common.sh" <<'STUB'
printf 'common\n' >> "$TEST_SOURCE_LOG"
STUB
cat > "$project/scripts/timer.d/actions.sh" <<'STUB'
printf 'actions\n' >> "$TEST_SOURCE_LOG"
STUB
cat > "$project/scripts/timer.d/daemon.sh" <<'STUB'
run_daemon() { printf 'daemon\n'; }
timer_add() { :; }
timer_add_at() { :; }
timer_up() { :; }
timer_down() { :; }
timer_delete() { :; }
update_color() { :; }
set_comment() { :; }
refresh() { :; }
refresh_add() { :; }
toggle_pause() { :; }
STUB
cat > "$work/bin/dirname" <<'WRAPPER'
#!/usr/bin/env bash
printf 'dirname\n' >> "$TEST_DIRNAME_LOG"
exit 99
WRAPPER
chmod +x "$work/bin/dirname"
export PATH="$work/bin:$PATH" TEST_DIRNAME_LOG="$work/dirname.log"

for mode in absolute relative; do
    : > "$work/source.log"
    if [[ "$mode" == absolute ]]; then
        output="$(TEST_SOURCE_LOG="$work/source.log" bash "$project/scripts/timer")" || fail 'absolute invocation failed'
    else
        output="$(cd "$work" && TEST_SOURCE_LOG="$work/source.log" bash 'Timer Project With Spaces/scripts/timer')" || fail 'relative invocation failed'
    fi
    [[ "$output" == daemon ]] || fail "$mode invocation returned unexpected output: $output"
    expected=$'env\ncommon\nactions'
    actual="$(cat "$work/source.log")"
    [[ "$actual" == "$expected" ]] || fail "$mode invocation sourced the wrong siblings: $actual"
done

[[ ! -s "$TEST_DIRNAME_LOG" ]] || fail "timer entry point spawned dirname"
echo 'Timer built-in script-dir fast path, absolute/relative paths with spaces, and no dirname subprocess: OK'
