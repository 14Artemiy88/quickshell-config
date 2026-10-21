#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "Top Apps process grouping: FAIL: $*" >&2; exit 1; }
test_runtime_dir="$(mktemp -d)"
trap 'rm -rf "$test_runtime_dir"' EXIT
export XDG_RUNTIME_DIR="$test_runtime_dir"
source_script="$ROOT/scripts/system_monitor.d/top_apps.sh"
[[ -f "$source_script" ]] || fail "top_apps.sh is missing"
# Deterministic fixture: Zen and Firefox helpers should be attributed to their own browser groups.
source "$source_script"
fixture=$'init\t0.0\t1000\t1\t0\nzen\t12.0\t100000\t101\t1\nzen\t18.0\t300000\t102\t101\nzen\t1.0\t25000\t103\t101\nIsolated Web Co\t15.0\t450000\t201\t102\nIsolated Web Co\t2.0\t50000\t202\t201\nfirefox\t20.0\t600000\t301\t1\nIsolated Web Co\t17.0\t100000\t302\t301\nvlc\t10.0\t1200000\t401\t1\ncode\t8.0\t50000\t501\t1\ntelegram\t7.0\t90000\t601\t1\nqbittorrent\t6.0\t70000\t701\t1\nbash\t0.5\t10000\t801\t1'

cpu_groups="$(printf '%s\n' "$fixture" | aggregate_process_rows cpu)"
mem_groups="$(printf '%s\n' "$fixture" | aggregate_process_rows mem)"

# The shell-side row limiter must preserve numeric descending sort and both
# historical limit semantics: zero means unlimited, a positive value caps rows.
all_mem_rows="$(printf '%s\n' "$fixture" | aggregate_process_rows mem 0)"
limited_mem_rows="$(printf '%s\n' "$fixture" | aggregate_process_rows mem 2)"
[[ "$(printf '%s\n' "$all_mem_rows" | awk 'NF {n++} END {print n+0}')" -gt 5 ]] || fail "row_limit=0 should return all groups"
[[ "$(printf '%s\n' "$limited_mem_rows" | awk 'NF {n++} END {print n+0}')" == 2 ]] || fail "row_limit=2 should return exactly two groups"
first_two="$(printf '%s\n' "$all_mem_rows" | head -n 2)"
[[ "$limited_mem_rows" == "$first_two" ]] || fail "limited output must preserve the sorted prefix"
aggregate_body="$(sed -n '/^aggregate_process_rows() {/,/^}/p' "$source_script")"
! grep -Fq 'sort -t "$tab" -k2,2nr | awk -v limit=' <<< "$aggregate_body" || fail "row-limit AWK subprocess is still present"

cpu_zen="$(printf '%s\n' "$cpu_groups" | awk -F '\t' '$1 == "zen" { print; exit }')"
[[ -n "$cpu_zen" ]] || fail "Zen aggregate is absent from CPU ranking"
IFS=$'\t' read -r name total count pid <<< "$cpu_zen"
[[ "$name" == "zen" ]] || fail "unexpected CPU group name: $name"
[[ "$total" == "48.0000" ]] || fail "Zen CPU should include isolated web content and sum to 48.0000, got $total"
[[ "$count" == "5" ]] || fail "Zen group should contain its 3 main and 2 isolated-content processes, got $count"
[[ "$pid" == "102" ]] || fail "Zen representative CPU PID should be highest-CPU member 102, got $pid"

mem_zen="$(printf '%s\n' "$mem_groups" | awk -F '\t' '$1 == "zen" { print; exit }')"
[[ -n "$mem_zen" ]] || fail "Zen aggregate is absent from memory ranking"
IFS=$'\t' read -r name total count pid <<< "$mem_zen"
[[ "$total" == "925000.0000" ]] || fail "Zen RSS should include isolated web content and sum to 925000 KiB, got $total"
[[ "$count" == "5" ]] || fail "Zen memory group should contain 5 processes, got $count"
[[ "$pid" == "201" ]] || fail "Zen representative memory PID should be highest-RSS member 201, got $pid"

# Isolated content under Firefox must map to Firefox, not Zen or a shared helper group.
firefox_cpu="$(printf '%s\n' "$cpu_groups" | awk -F '\t' '$1 == "firefox" { print; exit }')"
[[ -n "$firefox_cpu" ]] || fail "Firefox aggregate is absent from CPU ranking"
IFS=$'\t' read -r name total count pid <<< "$firefox_cpu"
[[ "$total" == "37.0000" && "$count" == "2" ]] || fail "Firefox should aggregate only its own process tree (expected 37.0000 CPU across 2 PIDs, got $total across $count)"

if printf '%s\n' "$cpu_groups" "$mem_groups" | grep -q '^Isolated Web Co\>'; then
    fail "attributed isolated web content still appears as a separate app"
fi

# Verify aggregation happens before ranking: only distinct grouped names are listed.
cpu_count="$(printf '%s\n' "$cpu_groups" | awk 'NF {n++} END {print n+0}')"
[[ "$cpu_count" == "5" ]] || fail "CPU result should contain five groups, got $cpu_count"
duplicate_names="$(printf '%s\n' "$cpu_groups" | cut -f1 | sort | uniq -d | wc -l)"
[[ "$duplicate_names" == "0" ]] || fail "CPU output contains duplicate process groups"

# The live producer must preserve the widget schema and expose group size.
command -v jq >/dev/null 2>&1 || fail "jq is required by the project but unavailable"
live="$(get_top_apps)" || fail "get_top_apps failed"
printf '%s\n' "$live" | jq -e '
  (.cpu | type == "array" and length <= 5 and all(.[]; (.processCount|type)=="number" and .processCount >= 1 and (.ratio|type)=="number" and .ratio >= 0 and .ratio <= 1)) and
  (.mem | type == "array" and length <= 5 and all(.[]; (.processCount|type)=="number" and .processCount >= 1 and (.ratio|type)=="number" and .ratio >= 0 and .ratio <= 1))
' >/dev/null || fail "live producer JSON does not contain valid aggregate metadata"

# GoLand should include live Go toolchain descendants (notably compile/link)
# in its own row, rather than inflating the generic System/other remainder.
goland_fixture=$'goland\t4.0000\t1000\t901\t1\ngo\t10.0000\t2000\t902\t901\ncompile\t22.0000\t3000\t903\t902\nlink\t5.0000\t500\t904\t902\nasm\t3.0000\t600\t905\t902\nunrelated\t40.0000\t600\t906\t1\ncompile\t7.0000\t700\t907\t906'
goland_groups="$(printf '%s\n' "$goland_fixture" | aggregate_process_rows cpu)"
goland_row="$(printf '%s\n' "$goland_groups" | awk -F '\t' '$1 == "goland" { print; exit }')"
[[ -n "$goland_row" ]] || fail "GoLand aggregate is missing"
IFS=$'\t' read -r name total count pid <<< "$goland_row"
[[ "$total" == "44.0000" && "$count" == "5" ]] || fail "GoLand should include root plus go/compile/link/asm descendants (expected 44.0000 across 5 processes, got $total across $count)"
compile_row="$(printf '%s\n' "$goland_groups" | awk -F '\t' '$1 == "compile" { print; exit }')"
IFS=$'\t' read -r name total count pid <<< "$compile_row"
[[ "$total" == "7.0000" && "$count" == "1" ]] || fail "unrelated compile process should not be attributed to GoLand (got $total across $count)"

echo "Top Apps process grouping and browser/GoLand attribution: OK"
