#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
CHECK="$ROOT/CHECK.sh"

# Every shell test must be routed through the summary/progress runner.
if grep -Eq '^bash "\$ROOT/tests/' "$CHECK"; then
    echo 'CHECK.sh still invokes tests directly instead of using run_test' >&2
    exit 1
fi
if grep -Eq '^run_test "\$ROOT/tests/[^" ]+"' "$CHECK"; then
    :
else
    echo 'CHECK.sh has no run_test invocations' >&2
    exit 1
fi

# Confirm the runner prints progress, failure details, and a final duration summary.
grep -Fq '%sPASS%s %s\n' "$CHECK"
grep -Fq '%sFAIL%s %s (exit %s)\n' "$CHECK"
grep -Fq 'cat "$CHECK_LOG" >&2' "$CHECK"
grep -Fq 'CHECK COMPLETE%s:' "$CHECK"
grep -Fq 'CHECK FAILED%s:' "$CHECK"
grep -Fq 'CHECK INTERRUPTED%s:' "$CHECK"
grep -Fq "trap 'exit 130' INT" "$CHECK"
grep -Fq "trap 'exit 143' TERM" "$CHECK"
grep -Fq 'CHECK_STARTED=$SECONDS' "$CHECK"

# Avoid restoring the previous verbose QML file dump / per-test heading stream.
if grep -Eq '^echo "==' "$CHECK"; then
    echo 'CHECK.sh still contains verbose per-test headings' >&2
    exit 1
fi

printf 'CHECK.sh concise progress/failure/summary output: OK\n'
