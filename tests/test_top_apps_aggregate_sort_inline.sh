#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "Top Apps inline aggregate sorting: FAIL: $*" >&2; exit 1; }
source "$ROOT/scripts/system_monitor.d/top_apps.sh"

# Equal-key rows intentionally arrive out of order. GNU sort's previous
# `-k2,2nr` behavior was numeric descending, with C-locale full-row ascending
# tie-breaks; the in-process AWK quicksort must preserve that exact order.
fixture=$'zeta\t1.0000\t100\t11\t1\nalpha\t1.0000\t100\t12\t1\nmiddle\t2.0000\t200\t13\t1\nbeta\t1.0000\t100\t14\t1\nzero\t0.0000\t50\t15\t1'
expected_cpu=$'middle\t2.0000\t1\t13\nalpha\t1.0000\t1\t12\nbeta\t1.0000\t1\t14\nzeta\t1.0000\t1\t11'
expected_mem=$'middle\t200.0000\t1\t13\nalpha\t100.0000\t1\t12\nbeta\t100.0000\t1\t14\nzeta\t100.0000\t1\t11\nzero\t50.0000\t1\t15'

actual_cpu="$(printf '%s\n' "$fixture" | aggregate_process_rows cpu 0)"
actual_mem="$(printf '%s\n' "$fixture" | aggregate_process_rows mem 0)"
[[ "$actual_cpu" == "$expected_cpu" ]] || fail "CPU sorting/tie order changed: [$actual_cpu]"
[[ "$actual_mem" == "$expected_mem" ]] || fail "RAM sorting/tie order changed: [$actual_mem]"

limited_cpu="$(printf '%s\n' "$fixture" | aggregate_process_rows cpu 2)"
expected_limited_cpu=$'middle\t2.0000\t1\t13\nalpha\t1.0000\t1\t12'
[[ "$limited_cpu" == "$expected_limited_cpu" ]] || fail 'CPU row limit must return the sorted prefix'

limited_mem="$(printf '%s\n' "$fixture" | aggregate_process_rows mem 3)"
expected_limited_mem=$'middle\t200.0000\t1\t13\nalpha\t100.0000\t1\t12\nbeta\t100.0000\t1\t14'
[[ "$limited_mem" == "$expected_limited_mem" ]] || fail 'RAM row limit must return the sorted prefix'

body="$(sed -n '/^aggregate_process_rows() {/,/^}/p' "$ROOT/scripts/system_monitor.d/top_apps.sh")"
! grep -Fq 'LC_ALL=C sort -t' <<< "$body" || fail 'external sort still runs in aggregate_process_rows'
! grep -Fq '| {' <<< "$body" || fail 'shell pipeline stage is still used to limit the sorted rows'
grep -Fq 'quicksort(1, out_count)' <<< "$body" || fail 'in-process quicksort invocation is missing'

echo 'Top Apps inline aggregate sorting: OK'
