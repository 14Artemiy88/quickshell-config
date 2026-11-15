#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
CHECK="$ROOT/CHECK.sh"

# Colors are independently enabled for stdout/stderr only on usable TTYs.
grep -Fq '[[ -t 1 && -z "${NO_COLOR:-}" && "${TERM:-}" != "dumb" ]]' "$CHECK"
grep -Fq '[[ -t 2 && -z "${NO_COLOR:-}" && "${TERM:-}" != "dumb" ]]' "$CHECK"
grep -Fq "CHECK_CYAN_OUT=\$'" "$CHECK"
grep -Fq "CHECK_GREEN_OUT=\$'" "$CHECK"
grep -Fq "CHECK_RED_OUT=\$'" "$CHECK"
grep -Fq '033[36m' "$CHECK"
grep -Fq '033[32m' "$CHECK"
grep -Fq '033[31m' "$CHECK"

# Headers are cyan; only PASS/FAIL status labels are green/red.
grep -Fq '"$CHECK_CYAN_OUT" "$CHECK_RESET_OUT" "$QML_COUNT" "$CHECK_TOTAL"' "$CHECK"
grep -Fq '"$CHECK_CURRENT" "$CHECK_TOTAL" "$CHECK_GREEN_OUT" "$CHECK_RESET_OUT" "$name"' "$CHECK"
grep -Fq '"$CHECK_CURRENT" "$CHECK_TOTAL" "$CHECK_RED_ERR" "$CHECK_RESET_ERR" "$name" "$status"' "$CHECK"
grep -Fq '"$CHECK_CYAN_OUT" "$CHECK_RESET_OUT" "$CHECK_GREEN_OUT" "$CHECK_RESET_OUT" "$name"' "$CHECK"
grep -Fq 'CHECK COMPLETE%s:' "$CHECK"
grep -Fq 'CHECK FAILED%s:' "$CHECK"

printf 'CHECK.sh terminal color formatting and NO_COLOR fallback: OK\n'
