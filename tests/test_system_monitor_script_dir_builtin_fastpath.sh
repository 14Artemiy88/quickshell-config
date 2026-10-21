#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="$ROOT/scripts/system_monitor"
fail() { printf 'System Monitor script-dir fast path: FAIL: %s\n' "$1" >&2; exit 1; }

grep -Fq 'SCRIPT_PATH="${BASH_SOURCE[0]}"' "$TARGET" || fail 'direct BASH_SOURCE path resolution is missing'
grep -Fq 'source "$SCRIPT_DIR/system_monitor.d/network_stat.sh"' "$TARGET" || fail 'sibling paths do not use SCRIPT_DIR'
if grep -Eq 'dirname[[:space:]]+"\$0"' "$TARGET"; then
    fail 'external dirname remains in System Monitor source prologue'
fi

work="$(mktemp -d)"
trap 'rm -rf -- "$work"' EXIT
project="$work/Project With Spaces"
mkdir -p "$project/scripts/system_monitor.d" "$work/bin" "$work/runtime"
cp "$TARGET" "$project/scripts/system_monitor"
cat > "$project/scripts/env" <<'STUB'
printf 'env\n' >> "$TEST_SOURCE_LOG"
STUB
cat > "$project/scripts/system_monitor.d/common.sh" <<'STUB'
printf 'common\n' >> "$TEST_SOURCE_LOG"
system_monitor_assemble_payload() { printf '{"stub":true}\n'; }
STUB
cat > "$project/scripts/system_monitor.d/network_stat.sh" <<'STUB'
printf 'network_stat\n' >> "$TEST_SOURCE_LOG"
get_network_stat() { :; }
STUB
cat > "$project/scripts/system_monitor.d/top_apps.sh" <<'STUB'
printf 'top_apps\n' >> "$TEST_SOURCE_LOG"
get_top_apps() { :; }
STUB
cat > "$project/scripts/system_monitor.d/volumes.sh" <<'STUB'
printf 'volumes\n' >> "$TEST_SOURCE_LOG"
get_volumes() { :; }
STUB
cat > "$project/scripts/system_monitor.d/network_connections.sh" <<'STUB'
printf 'network_connections\n' >> "$TEST_SOURCE_LOG"
get_network_connections() { :; }
STUB
real_dirname="$(command -v dirname)"
export TEST_REAL_DIRNAME="$real_dirname" TEST_DIRNAME_LOG="$work/dirname.log"
cat > "$work/bin/dirname" <<'WRAPPER'
#!/usr/bin/env bash
printf 'dirname\n' >> "$TEST_DIRNAME_LOG"
exec "$TEST_REAL_DIRNAME" "$@"
WRAPPER
chmod +x "$work/bin/dirname"
export PATH="$work/bin:$PATH"
export XDG_RUNTIME_DIR="$work/runtime"

for mode in absolute relative; do
    : > "$work/source.log"
    if [[ "$mode" == absolute ]]; then
        output="$(TEST_SOURCE_LOG="$work/source.log" bash "$project/scripts/system_monitor" 0 0 0 0 0 0 0)" || fail 'absolute invocation failed'
    else
        output="$(cd "$work" && TEST_SOURCE_LOG="$work/source.log" bash 'Project With Spaces/scripts/system_monitor' 0 0 0 0 0 0 0)" || fail 'relative invocation failed'
    fi
    [[ "$output" == '{"stub":true}' ]] || fail "$mode invocation returned unexpected output: $output"
    [[ "$(wc -l < "$work/source.log")" -eq 6 ]] || fail "$mode invocation did not source exactly six sibling files"
done

[[ ! -s "$TEST_DIRNAME_LOG" ]] || fail "system_monitor spawned dirname: $(cat "$TEST_DIRNAME_LOG")"
echo 'System Monitor built-in script-dir fast path, absolute/relative paths with spaces, and no dirname subprocess: OK'
