#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "Top Apps Bash state counter read: FAIL: $*" >&2; exit 1; }
source "$ROOT/scripts/system_monitor.d/top_apps.sh"

# The production snapshot parser should read the previous S record with Bash,
# not spawn AWK just to extract two fields from its own small state file.
body="$(sed -n '/^_get_process_snapshot_unlocked() {/,/^}/p' "$ROOT/scripts/system_monitor.d/top_apps.sh")"
grep -Fq 'read -r state_marker state_a state_b _;' <<< "$body" || fail 'Bash state-file reader is missing'
! grep -Fq 'previous_system_counters="$(awk' <<< "$body" || fail 'AWK subprocess still parses previous system counters'
grep -Fq 'C) previous_clk_tck="$state_a"' <<< "$body" || fail 'cached CLK_TCK state record is not read'
grep -Fq 'clk_tck="$previous_clk_tck"' <<< "$body" || fail 'cached CLK_TCK is not reused'
grep -Fq "printf 'T\\t%s\\nC\\t%s\\n'" <<< "$body" || fail 'CLK_TCK is not persisted in the next state' 
# Once a baseline exists, use the state file directly: no steady-state
# `cat` copy or third temporary file is needed. The lock held by the caller
# guarantees the previous state is not replaced during this read.
[[ "$body" == *'previous_file="$state_file"'* ]] || fail 'existing state file is not used directly as previous sample'
! grep -Fq 'cat -- "$state_file" > "$previous_file"' <<< "$body" || fail 'state file is still copied through cat on every poll'
# Keep snapshot/state file descriptors open while iterating process rows.
grep -Fq 'exec {current_fd}>>"$current_file"' <<< "$body" || fail 'current snapshot descriptor is not reused'
grep -Fq 'exec {next_state_fd}>>"$next_state"' <<< "$body" || fail 'next-state descriptor is not reused'
! grep -Fq '>> "$current_file"' <<< "$body" || fail 'current snapshot still reopens the file for each process'
! grep -Fq 'printf '''P\t%s\t%s\t%s\n''' "$pid" "$starttime" "$ticks" >> "$next_state"' <<< "$body" || fail 'next state still reopens the file for each process'

# Exercise the same record layout and validation used by the collector.
fixture="$(mktemp)"
trap 'rm -f "$fixture"' EXIT
printf 'T\t1200\nC\t100\nS\t98765\t123456\nL\t80.0000\nP\t42\t100\t300\n' > "$fixture"
previous_system_counters=''
while IFS=$'\t' read -r state_marker state_a state_b _; do
    if [[ "$state_marker" == "S" ]]; then
        previous_system_counters="$state_a $state_b"
        break
    fi
done < "$fixture"
[[ "$previous_system_counters" == '98765 123456' ]] || fail "unexpected counters: $previous_system_counters"
[[ "$previous_system_counters" =~ ^([0-9]+)[[:space:]]+([0-9]+)$ ]] || fail 'valid counters rejected'
[[ "${BASH_REMATCH[1]} ${BASH_REMATCH[2]}" == '98765 123456' ]] || fail 'counter fields changed'

echo 'Top Apps Bash state counter read: OK'
