#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
CHECK="$ROOT/CHECK.sh"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf -- "$TMP_DIR"' EXIT

# Extract the real summary and runner functions without executing the 500+ test suite.
sed -n '/^finish_check() {/,/^}/p' "$CHECK" >"$TMP_DIR/runner-functions.sh"
sed -n '/^check_now_us() {/,/^}/p' "$CHECK" >>"$TMP_DIR/runner-functions.sh"
sed -n '/^run_test() {/,/^}/p' "$CHECK" >>"$TMP_DIR/runner-functions.sh"
sed -n '/^run_step() {/,/^}/p' "$CHECK" >>"$TMP_DIR/runner-functions.sh"
if ! grep -q '^run_test() {' "$TMP_DIR/runner-functions.sh" || ! grep -q '^run_step() {' "$TMP_DIR/runner-functions.sh"; then
    echo 'Could not extract CHECK.sh runner functions' >&2
    exit 1
fi

cat >"$TMP_DIR/pass.sh" <<'PASS'
#!/usr/bin/env bash
echo 'synthetic pass'
PASS
cat >"$TMP_DIR/fail-one.sh" <<'FAIL1'
#!/usr/bin/env bash
echo 'synthetic failure one diagnostic' >&2
exit 7
FAIL1
cat >"$TMP_DIR/fail-two.sh" <<'FAIL2'
#!/usr/bin/env bash
echo 'synthetic failure two diagnostic' >&2
exit 9
FAIL2
chmod +x "$TMP_DIR/"*.sh

CHECK_LOG="$TMP_DIR/current.log"
CHECK_TIMINGS_FILE="$TMP_DIR/timings.tsv"
CHECK_TOTAL=3
CHECK_CURRENT=0
CHECK_PASSED=0
CHECK_FAILED=0
CHECK_FAILED_TEST_NAMES=()
CHECK_STEP_TOTAL=0
CHECK_STEP_PASSED=0
CHECK_STEP_FAILED=0
CHECK_FAILED_STEP_NAMES=()
CHECK_GREEN_OUT=''
CHECK_RED_ERR=''
CHECK_CYAN_OUT=''
CHECK_CYAN_ERR=''
CHECK_RESET_OUT=''
CHECK_RESET_ERR=''
# shellcheck disable=SC1090
source "$TMP_DIR/runner-functions.sh"

if ! {
    run_test "$TMP_DIR/fail-one.sh"
    run_test "$TMP_DIR/pass.sh"
    run_test "$TMP_DIR/fail-two.sh"
} >"$TMP_DIR/test-runner.out" 2>&1; then
    echo 'run_test propagated a failure instead of continuing' >&2
    cat "$TMP_DIR/test-runner.out" >&2
    exit 1
fi

[[ "$CHECK_CURRENT" == 3 ]]
[[ "$CHECK_PASSED" == 1 ]]
[[ "$CHECK_FAILED" == 2 ]]
[[ "${#CHECK_FAILED_TEST_NAMES[@]}" == 2 ]]
[[ "$(wc -l < "$CHECK_TIMINGS_FILE")" == 3 ]]
[[ "${CHECK_FAILED_TEST_NAMES[0]}" == 'fail-one.sh (exit 7)' ]]
[[ "${CHECK_FAILED_TEST_NAMES[1]}" == 'fail-two.sh (exit 9)' ]]
grep -Fq 'synthetic failure one diagnostic' "$TMP_DIR/test-runner.out"
grep -Fq 'synthetic failure two diagnostic' "$TMP_DIR/test-runner.out"
grep -Fq 'fail-one.sh (exit 7) — continuing' "$TMP_DIR/test-runner.out"
grep -Fq 'fail-two.sh (exit 9) — continuing' "$TMP_DIR/test-runner.out"

if ! {
    run_step 'synthetic failing step' bash -c 'echo "synthetic step diagnostic" >&2; exit 11'
    run_step 'synthetic passing step' bash -c 'echo "synthetic step pass"'
} >"$TMP_DIR/step-runner.out" 2>&1; then
    echo 'run_step propagated a failure instead of continuing' >&2
    cat "$TMP_DIR/step-runner.out" >&2
    exit 1
fi

[[ "$CHECK_STEP_TOTAL" == 2 ]]
[[ "$CHECK_STEP_PASSED" == 1 ]]
[[ "$CHECK_STEP_FAILED" == 1 ]]
[[ "${#CHECK_FAILED_STEP_NAMES[@]}" == 1 ]]
[[ "${CHECK_FAILED_STEP_NAMES[0]}" == 'synthetic failing step (exit 11)' ]]
grep -Fq 'synthetic step diagnostic' "$TMP_DIR/step-runner.out"
grep -Fq 'synthetic failing step (exit 11) — continuing' "$TMP_DIR/step-runner.out"

# Exercise the actual EXIT summary and ensure a failed aggregate run exits non-zero.
cat >"$TMP_DIR/final-status.sh" <<'FINAL'
#!/usr/bin/env bash
set -e
CHECK_LOG="${CHECK_LOG_TEST:?}"
CHECK_TIMINGS_FILE="$(mktemp)"
CHECK_STARTED=$SECONDS
CHECK_TOTAL=1; CHECK_CURRENT=0; CHECK_PASSED=0; CHECK_FAILED=0
CHECK_STEP_TOTAL=1; CHECK_STEP_PASSED=0; CHECK_STEP_FAILED=1
CHECK_FAILED_TEST_NAMES=(); CHECK_FAILED_STEP_NAMES=("synthetic-final-step-failure (exit 11)")
CHECK_CYAN_OUT=''; CHECK_GREEN_OUT=''; CHECK_RED_OUT=''; CHECK_RESET_OUT=''
CHECK_CYAN_ERR=''; CHECK_GREEN_ERR=''; CHECK_RED_ERR=''; CHECK_RESET_ERR=''
FINAL
cat "$TMP_DIR/runner-functions.sh" >>"$TMP_DIR/final-status.sh"
cat >>"$TMP_DIR/final-status.sh" <<'FINAL'
trap finish_check EXIT
CHECK_FAILED=1
CHECK_FAILED_TEST_NAMES+=("synthetic-final-failure (exit 7)")
if ((CHECK_FAILED > 0 || CHECK_STEP_FAILED > 0)); then
    exit 1
fi
FINAL
if CHECK_LOG_TEST="$TMP_DIR/final.log" bash "$TMP_DIR/final-status.sh" >"$TMP_DIR/final-status.out" 2>&1; then
    echo 'CHECK.sh aggregate failure incorrectly returned zero' >&2
    cat "$TMP_DIR/final-status.out" >&2
    exit 1
else
    final_status=$?
fi
[[ "$final_status" == 1 ]]
grep -Fq 'CHECK FAILED:' "$TMP_DIR/final-status.out"
grep -Fq 'synthetic-final-failure (exit 7)' "$TMP_DIR/final-status.out"
grep -Fq 'steps 0/1 passed, 1 failed' "$TMP_DIR/final-status.out"
grep -Fq 'synthetic-final-step-failure (exit 11)' "$TMP_DIR/final-status.out"

# The main script must still return non-zero after the complete suite when any item failed.
grep -Fq 'if ((CHECK_FAILED > 0 || CHECK_STEP_FAILED > 0)); then' "$CHECK"
grep -Fq 'Do not stop early:' "$CHECK"

echo 'CHECK.sh runner continues after test and step failures, preserves diagnostics, and records failures: OK'
