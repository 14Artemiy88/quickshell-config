#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "CPU sampling inline assignments: FAIL: $*" >&2; exit 1; }
source "$ROOT/scripts/cpu_stats.d/common.sh"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
stat_file="$work/stat"
mem_file="$work/meminfo"
cat > "$stat_file" <<'STAT'
cpu 10000 500 1500 25000 300 60 90 20 800 100
cpu0 100 5 20 300 10 2 3 1 20 2
cpu2 400 10 40 500 20 4 6 2 40 4
STAT
cat > "$mem_file" <<'MEM'
MemTotal: 1000 kB
MemFree: 100 kB
MemAvailable: 300 kB
MEM

# Old stdout wrappers and the new caller-variable APIs must return identical
# data for the same snapshots. This also covers multiline values and field order.
old_before="$(cpu_read_counters_with_ids "$stat_file")"
cpu_read_counters_with_ids_into new_before "$stat_file" || fail "direct CPU snapshot read failed"
[[ "$new_before" == "$old_before" ]] || fail "direct snapshot differs from stdout API"
old_after=$'cpu2 460 580\ncpu0 130 360'
old_percent="$(cpu_usage_snapshot_percentages "$old_before" "$old_after")"
cpu_usage_snapshot_percentages_into new_percent "$old_before" "$old_after"
[[ "$new_percent" == "$old_percent" ]] || fail "direct percentages differ from stdout API"
old_ram="$(mem_usage_percent "$mem_file")"
mem_usage_percent_into new_ram "$mem_file"
[[ "$new_ram" == "$old_ram" ]] || fail "direct memory percentage differs from stdout API"
[[ "$new_ram" == '70' ]] || fail "unexpected memory percentage: $new_ram"

# Both production CPU collectors should use caller-variable APIs on their hot
# path, rather than capturing these helpers through command substitutions.
for script in "$ROOT/scripts/cpu_stats" "$ROOT/scripts/cpu_stats_once"; do
    grep -Fq 'cpu_read_counters_with_ids_into' "$script" || fail "$(basename "$script") misses direct counter reads"
    grep -Fq 'cpu_usage_snapshot_percentages_into' "$script" || fail "$(basename "$script") misses direct percentage calculation"
    grep -Fq 'mem_usage_percent_into' "$script" || fail "$(basename "$script") misses direct memory calculation"
    if grep -Eq '=\$\((cpu_read_counters_with_ids|cpu_usage_snapshot_percentages|mem_usage_percent) ' "$script"; then
        fail "$(basename "$script") still captures hot-path helper output"
    fi
done

echo 'CPU sampling inline assignments: OK'
