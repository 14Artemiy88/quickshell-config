#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "Top Apps batched formatting: FAIL: $*" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || fail 'jq is required'
source "$ROOT/scripts/system_monitor.d/top_apps.sh"

cpu_rows=$'quoted "app"\t12.3456\t2\t123\nheavy\t250.0000\t1\t456'
cpu_json="$(format_top_apps_rows_json "$cpu_rows" cpu 800)" || fail 'CPU format failed'
jq -e '
  length == 2 and
  .[0] == {"name":"quoted \"app\"","value":"1.5%","pid":"123","processCount":2,"ratio":0.0154} and
  .[1] == {"name":"heavy","value":"31.2%","pid":"456","processCount":1,"ratio":0.3125}
' <<< "$cpu_json" >/dev/null || fail "CPU labels/ratios/schema changed: $cpu_json"

mem_rows=$'small\t512\t1\t10\nmegabyte\t1024\t2\t20\ngigabyte\t1048576\t3\t30'
mem_json="$(format_top_apps_rows_json "$mem_rows" mem 16000)" || fail 'RAM format failed'
jq -e '
  length == 3 and
  .[0].value == "512 Kb" and .[0].ratio == 0.032 and
  .[1].value == "1.0 Mb" and .[1].ratio == 0.064 and
  .[2].value == "1.0 Gb" and .[2].ratio == 1
' <<< "$mem_json" >/dev/null || fail "RAM labels/ratios/schema changed: $mem_json"

empty_json="$(format_top_apps_rows_json '' cpu 800)" || fail 'empty format failed'
jq -e 'type == "array" and length == 0' <<< "$empty_json" >/dev/null || fail "empty rows should encode as []: $empty_json"

# The production function should no longer format each row with its own AWK/jq process.
function_body="$(sed -n '/^format_top_apps_rows_json() {/,/^}/p' "$ROOT/scripts/system_monitor.d/top_apps.sh")"
[[ "$(grep -c "jq -Rn" <<< "$function_body")" -eq 1 ]] || fail 'rows are not encoded in a single jq invocation'
[[ "$(grep -Fc 'printf "%s\t%s\t%s\t%d\t%.4f\n"' <<< "$function_body")" -eq 1 ]] || fail 'rows are not formatted in one AWK invocation'

# Ensure this optimization stays on the established KDE Neon-compatible path; it must not restore v666 glob parsing.
! grep -Fq '"$proc_root"/[0-9]*/stat' "$ROOT/scripts/system_monitor.d/top_apps.sh" || fail 'v666 direct /proc glob was reintroduced'

echo 'Top Apps batched formatting: OK'
