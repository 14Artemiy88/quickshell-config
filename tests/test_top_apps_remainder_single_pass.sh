#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "Top Apps remainder single pass: FAIL: $*" >&2; exit 1; }
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin"
cat > "$TMP/bin/awk" <<'WRAPPER'
#!/bin/bash
printf 'awk\n' >> "$AWK_CALL_LOG"
exec /usr/bin/awk "$@"
WRAPPER
chmod +x "$TMP/bin/awk"
export AWK_CALL_LOG="$TMP/awk-calls.log"
export PATH="$TMP/bin:$PATH"
source "$ROOT/scripts/system_monitor.d/top_apps.sh"

rows=$'compile\t75.0000\t1024\t101\ngoland\t74.0000\t2048\t102\nkwin_wayland\t24.0000\t3072\t103\nzen\t18.0000\t4096\t104'
output="$(add_system_cpu_remainder_row "$rows" 100 800 'System remainder')"
expected=$'compile\t75.0000\t1024\t101\ngoland\t74.0000\t2048\t102\nkwin_wayland\t24.0000\t3072\t103\nzen\t18.0000\t4096\t104\nSystem remainder\t609.0000\t1\t0'
[[ "$output" == "$expected" ]] || fail "combined output differed: $output"
[[ "$(wc -l < "$AWK_CALL_LOG")" -eq 1 ]] || fail "expected one AWK process, got $(wc -l < "$AWK_CALL_LOG")"

: > "$AWK_CALL_LOG"
output="$(add_system_cpu_remainder_row '' 0 800 'No remainder')"
[[ -z "$output" ]] || fail "zero load with no visible rows should produce no output: $output"
[[ "$(wc -l < "$AWK_CALL_LOG")" -eq 1 ]] || fail 'empty input should still use only one AWK process'

echo 'Top Apps remainder single pass: OK'
