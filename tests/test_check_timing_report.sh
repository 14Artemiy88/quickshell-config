#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
CHECK="$ROOT/CHECK.sh"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf -- "$TMP_DIR"' EXIT

# Load only the actual runner functions; do not execute the whole suite.
sed -n '/^finish_check() {/,/^}/p' "$CHECK" >"$TMP_DIR/runner-functions.sh"
sed -n '/^check_now_us() {/,/^}/p' "$CHECK" >>"$TMP_DIR/runner-functions.sh"
sed -n '/^run_test() {/,/^}/p' "$CHECK" >>"$TMP_DIR/runner-functions.sh"

cat >"$TMP_DIR/slow.sh" <<'TEST'
#!/usr/bin/env bash
sleep 0.08
TEST
cat >"$TMP_DIR/medium.sh" <<'TEST'
#!/usr/bin/env bash
sleep 0.04
TEST
cat >"$TMP_DIR/fast.sh" <<'TEST'
#!/usr/bin/env bash
sleep 0.01
TEST

CHECK_LOG="$TMP_DIR/test.log"
CHECK_TIMINGS_FILE="$TMP_DIR/timings.tsv"
CHECK_STARTED=$SECONDS
CHECK_TOTAL=3
CHECK_CURRENT=0
CHECK_PASSED=0
CHECK_FAILED=0
CHECK_STEP_TOTAL=0
CHECK_STEP_PASSED=0
CHECK_STEP_FAILED=0
CHECK_FAILED_TEST_NAMES=()
CHECK_FAILED_STEP_NAMES=()
CHECK_CYAN_OUT=''; CHECK_GREEN_OUT=''; CHECK_RED_OUT=''; CHECK_RESET_OUT=''
CHECK_CYAN_ERR=''; CHECK_GREEN_ERR=''; CHECK_RED_ERR=''; CHECK_RESET_ERR=''
# shellcheck disable=SC1090
source "$TMP_DIR/runner-functions.sh"

# The clock helper must emit one fixed-width epoch-microsecond value. In
# particular, its seconds and fractional fields must come from one snapshot.
check_now_us
[[ "$CHECK_NOW_US" =~ ^[0-9]{16}$ ]] || {
    echo "check_now_us returned an invalid timestamp: $CHECK_NOW_US" >&2
    exit 1
}
run_test "$TMP_DIR/slow.sh" >/dev/null
run_test "$TMP_DIR/medium.sh" >/dev/null
run_test "$TMP_DIR/fast.sh" >/dev/null
[[ "$(wc -l < "$CHECK_TIMINGS_FILE")" -eq 3 ]]
awk -F '\t' 'NF != 2 || $1 !~ /^[0-9]+$/ || $1 < 5000 || $1 > 500000 { exit 1 }' "$CHECK_TIMINGS_FILE"

finish_check >"$TMP_DIR/summary.out"
grep -Fq 'Slowest tests (top 10 of 3):' "$TMP_DIR/summary.out"
slow_line="$(grep -n 'slow.sh' "$TMP_DIR/summary.out" | cut -d: -f1)"
medium_line="$(grep -n 'medium.sh' "$TMP_DIR/summary.out" | cut -d: -f1)"
fast_line="$(grep -n 'fast.sh' "$TMP_DIR/summary.out" | cut -d: -f1)"
[[ -n "$slow_line" && -n "$medium_line" && -n "$fast_line" ]]
((slow_line < medium_line && medium_line < fast_line)) || {
    echo 'slowest-test report is not sorted by measured duration' >&2
    cat "$TMP_DIR/summary.out" >&2
    exit 1
}

grep -Fq 'CHECK COMPLETE:' "$TMP_DIR/summary.out"
echo 'CHECK.sh records microsecond per-test timings and reports slowest tests in measured order: OK'
