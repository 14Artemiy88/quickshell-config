#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
daemon="$ROOT/scripts/cpu_graph_daemon"
fail() { printf 'CPU graph state parse: FAIL: %s\n' "$*" >&2; exit 1; }

[[ -x "$daemon" ]] || fail "CPU graph daemon is missing"
if grep -Eq 'sed[[:space:]]+-n[[:space:]]+.[2]p|awk[[:space:]]+-F[[:space:]]*,|awk -F,' "$daemon"; then
    fail "external sed/awk history parsing returned"
fi

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

mkdir -p "$work/bin"
real_awk="$(command -v awk)"
real_sed="$(command -v sed)"
cat > "$work/bin/awk" <<'WRAPPER'
#!/bin/sh
printf 'awk\n' >> "$CPU_GRAPH_TEST_COMMAND_LOG"
exec "$CPU_GRAPH_TEST_REAL_AWK" "$@"
WRAPPER
cat > "$work/bin/sed" <<'WRAPPER'
#!/bin/sh
printf 'sed\n' >> "$CPU_GRAPH_TEST_COMMAND_LOG"
exec "$CPU_GRAPH_TEST_REAL_SED" "$@"
WRAPPER
chmod +x "$work/bin/awk" "$work/bin/sed"

proc_stat="$work/proc-stat"
cat > "$proc_stat" <<'STAT'
cpu 100 0 100 800 0 0 0 0 0 0
cpu0 100 0 100 800 0 0 0 0 0 0
STAT

run_case() {
    local name="$1" history="$2" expect_valid="$3"
    local state="$work/$name.state" output="$work/$name.out" log="$work/$name.commands"
    printf 'v2 200 1000\n%s\n' "$history" > "$state"
    : > "$output"
    : > "$log"
    PATH="$work/bin:$PATH" \
      CPU_GRAPH_TEST_COMMAND_LOG="$log" \
      CPU_GRAPH_TEST_REAL_AWK="$real_awk" CPU_GRAPH_TEST_REAL_SED="$real_sed" \
      CPU_GRAPH_PROC_STAT="$proc_stat" CPU_GRAPH_STATE="$state" CPU_GRAPH_INTERVAL=10 \
      "$daemon" > "$output" 2>/dev/null &
    daemon_pid=$!
    for _ in {1..100}; do
        [[ -s "$output" ]] && break
        sleep 0.01
    done
    [[ -s "$output" ]] || fail "$name daemon emitted no initial history"
    kill "$daemon_pid" 2>/dev/null || true
    wait "$daemon_pid" 2>/dev/null || true
    daemon_pid=""
    [[ ! -s "$log" ]] || fail "$name startup launched external history parser: $(tr '\n' ' ' < "$log")"
    if [[ "$expect_valid" == 1 ]]; then
        jq -e 'type == "array" and length == 51 and .[0] == 1 and .[-1] == 0' "$output" >/dev/null || \
            fail "$name valid history was not preserved after one sample"
    else
        jq -e 'type == "array" and length == 51 and all(.[]; . == 0)' "$output" >/dev/null || \
            fail "$name malformed history was not safely reset"
    fi
}

valid_history='0000'
for value in {1..50}; do valid_history+=",$value"; done
run_case valid-leading-zero-history "$valid_history" 1
bad_history='0'
for value in {1..49}; do bad_history+=",$value"; done
bad_history+=",101"
run_case out-of-range-history "$bad_history" 0

printf 'CPU graph state parse: OK\n'
