#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
REPORT="$(python3 "$ROOT/scripts/audit_tests.py")"
grep -Fq 'Registration mismatches: missing=0, unregistered=0, registered-more-than-once=0' <<<"$REPORT"
grep -Fq 'Exact source duplicate groups: 0' <<<"$REPORT"
grep -Fq 'Semantic overlap candidates:' <<<"$REPORT"
echo 'test inventory audit, exact duplicate guard and semantic overlap candidate report: OK'
