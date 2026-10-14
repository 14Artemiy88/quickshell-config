#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "CPU graph accounting: FAIL: $*" >&2; exit 1; }
helper="$ROOT/scripts/cpu_stats.d/common.sh"
daemon="$ROOT/scripts/cpu_graph_daemon"
[[ -f "$helper" && -x "$daemon" ]] || fail "CPU helper or graph daemon missing"
source "$helper"

work="$(mktemp -d)"
daemon_pid=""
cleanup() {
  if [[ -n "$daemon_pid" ]]; then
    kill "$daemon_pid" 2>/dev/null || true
    wait "$daemon_pid" 2>/dev/null || true
  fi
  rm -rf "$work"
}
trap cleanup EXIT

proc_stat="$work/proc-stat"
state="$work/graph-state"
out="$work/output"
cat > "$proc_stat" <<'STAT'
cpu 100 0 100 700 50 0 0 0 0 0
cpu0 10 0 10 70 5 0 0 0 0 0
STAT
[[ "$(cpu_read_aggregate_counters "$proc_stat")" == "200 950" ]] || \
  fail "aggregate counters do not include iowait/IRQ/softIRQ/steal using shared accounting"
[[ "$(cpu_usage_percent 200 950 235 1050)" == "35" ]] || \
  fail "expected CPU graph sample of 35%, got a different value"

# Run the real daemon with an isolated proc-stat fixture, then atomically update
# the counters during its interval. Its next sample should match cpu_stats.
CPU_GRAPH_PROC_STAT="$proc_stat" CPU_GRAPH_STATE="$state" CPU_GRAPH_INTERVAL=0.10 \
  "$daemon" > "$out" 2>/dev/null &
daemon_pid=$!
for _ in $(seq 1 100); do
  [[ -s "$out" ]] && break
  sleep 0.01
done
[[ -s "$out" ]] || fail "CPU graph daemon produced no initial sample"
cat > "$work/proc-stat-next" <<'STAT'
cpu 110 0 120 760 55 2 3 0 0 0
cpu0 11 0 12 76 5 1 1 0 0 0
STAT
mv -f "$work/proc-stat-next" "$proc_stat"
for _ in $(seq 1 100); do
  [[ "$(wc -l < "$out")" -ge 2 ]] && break
  sleep 0.01
done
[[ "$(wc -l < "$out")" -ge 2 ]] || fail "CPU graph daemon produced no second sample"
kill "$daemon_pid" 2>/dev/null || true
wait "$daemon_pid" 2>/dev/null || true
daemon_pid=""
jq -e 'type == "array" and length == 51 and .[-1] == 35' < <(sed -n '2p' "$out") >/dev/null || \
  fail "CPU graph sample didn't use shared accounting (expected final sample 35%)"
read -r state_version _ < "$state"
[[ "$state_version" == "v2" ]] || fail "CPU graph state wasn't atomically updated to v2"

# Legacy state remains readable for history, but its incompatible counters are
# deliberately discarded to avoid a one-frame spike during upgrade.
printf '100 20 30 400\n' > "$state"
history="$(printf '1,%.0s' {1..50})1"
printf '%s\n' "$history" >> "$state"
: > "$out"
CPU_GRAPH_PROC_STAT="$proc_stat" CPU_GRAPH_STATE="$state" CPU_GRAPH_INTERVAL=0.10 \
  "$daemon" > "$out" 2>/dev/null &
daemon_pid=$!
for _ in $(seq 1 100); do
  [[ -s "$out" ]] && break
  sleep 0.01
done
[[ -s "$out" ]] || fail "daemon failed to start with legacy state"
jq -e 'type == "array" and length == 51 and .[-1] == 0 and .[0] == 1' < <(head -n1 "$out") >/dev/null || \
  fail "legacy history wasn't retained with a clean zero baseline"
kill "$daemon_pid" 2>/dev/null || true
wait "$daemon_pid" 2>/dev/null || true
daemon_pid=""

# A persisted zero/zero v2 baseline can be left by an earlier run that could
# not read /proc/stat. It is not a valid baseline and must not create a first
# sample from the full boot-time counters.
history="$(printf '1,%.0s' {1..50})1"
printf 'v2 0 0\n%s\n' "$history" > "$state"
: > "$out"
CPU_GRAPH_PROC_STAT="$proc_stat" CPU_GRAPH_STATE="$state" CPU_GRAPH_INTERVAL=0.10 \
  "$daemon" > "$out" 2>/dev/null &
daemon_pid=$!
for _ in $(seq 1 100); do
  [[ -s "$out" ]] && break
  sleep 0.01
done
[[ -s "$out" ]] || fail "daemon failed to start with an invalid empty baseline"
jq -e 'type == "array" and length == 51 and .[-1] == 0 and .[0] == 1' < <(head -n1 "$out") >/dev/null || \
  fail "invalid zero/zero baseline produced a bogus first CPU sample"
kill "$daemon_pid" 2>/dev/null || true
wait "$daemon_pid" 2>/dev/null || true
daemon_pid=""

# Malformed per-core/aggregate counters are skipped by the shared reader.
cat > "$work/proc-stat-invalid" <<'STAT'
cpu bad 0 0 0 0 0 0 0 0 0
cpu0 bad 0 0 0 0 0 0 0 0 0
STAT
[[ -z "$(cpu_read_aggregate_counters "$work/proc-stat-invalid" || true)" ]] || \
  fail "aggregate reader accepted malformed counter data"
[[ -z "$(cpu_read_counters_with_ids "$work/proc-stat-invalid")" ]] || \
  fail "per-core reader accepted malformed counter data"
cat > "$work/proc-stat-truncated" <<'STAT'
cpu 100
cpu0 10
STAT
[[ -z "$(cpu_read_aggregate_counters "$work/proc-stat-truncated" || true)" ]] || \
  fail "aggregate reader accepted a truncated mandatory counter prefix"
[[ -z "$(cpu_read_counters_with_ids "$work/proc-stat-truncated")" ]] || \
  fail "per-core reader accepted a truncated mandatory counter prefix"

# A transiently invalid /proc/stat read must preserve the last graph history
# and baseline. Once counters become valid again, the sample spans the whole
# interval and must not include an artificial zero-load trough.
cat > "$proc_stat" <<'STAT'
cpu 100 0 100 700 0 0 0 0 0 0
cpu0 100 0 100 700 0 0 0 0 0 0
STAT
: > "$out"
CPU_GRAPH_PROC_STAT="$proc_stat" CPU_GRAPH_STATE="$state" CPU_GRAPH_INTERVAL=0.10 \
  "$daemon" > "$out" 2>/dev/null &
daemon_pid=$!
for _ in $(seq 1 100); do
  [[ -s "$out" ]] && break
  sleep 0.01
done
[[ -s "$out" ]] || fail "daemon produced no baseline before transient read failure"
cat > "$work/proc-stat-next" <<'STAT'
cpu bad 0 0 0 0 0 0 0 0 0
STAT
mv -f "$work/proc-stat-next" "$proc_stat"
for _ in $(seq 1 100); do
  [[ "$(wc -l < "$out")" -ge 2 ]] && break
  sleep 0.01
done
[[ "$(wc -l < "$out")" -ge 2 ]] || fail "daemon produced no output during transient read failure"
[[ "$(sed -n '1p' "$out")" == "$(sed -n '2p' "$out")" ]] || \
  fail "invalid /proc/stat sample changed the published history"
cat > "$work/proc-stat-next" <<'STAT'
cpu 110 0 110 720 0 0 0 0 0 0
cpu0 110 0 110 720 0 0 0 0 0 0
STAT
mv -f "$work/proc-stat-next" "$proc_stat"
for _ in $(seq 1 100); do
  [[ "$(wc -l < "$out")" -ge 3 ]] && break
  sleep 0.01
done
[[ "$(wc -l < "$out")" -ge 3 ]] || fail "daemon produced no sample after counters recovered"
jq -e 'type == "array" and length == 51 and .[-1] == 50' < <(sed -n '3p' "$out") >/dev/null || \
  fail "recovered CPU sample did not span the interval across the bad read"
kill "$daemon_pid" 2>/dev/null || true
wait "$daemon_pid" 2>/dev/null || true
daemon_pid=""

# Static regression guard: the graph must no longer use the old incomplete
# user+nice+system+idle formula or non-atomic multi-line state writes.
grep -Fq 'cpu_read_aggregate_counters' "$daemon" || fail "daemon doesn't use the shared CPU accounting"
grep -Fq 'cpu_usage_percent' "$daemon" || fail "daemon doesn't use shared percentage calculation"
grep -Fq "printf 'v2 %s %s\\n%s\\n'" "$daemon" || fail "versioned atomic state payload missing"
if grep -Eq 'u=\$\(\(user \+ nice \+ system\)\)|t=\$\(\(u \+ idle\)\)' "$daemon"; then
  fail "old incomplete CPU formula remains in graph daemon"
fi

echo "CPU graph accounting: OK"
