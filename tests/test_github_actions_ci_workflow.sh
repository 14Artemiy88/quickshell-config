#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT/.github/workflows/checks.yml" "$ROOT/CHECK.sh" <<'PY'
from pathlib import Path
import sys
workflow = Path(sys.argv[1]).read_text()
check = Path(sys.argv[2]).read_text()
required = {
    "push trigger": "  push:",
    "pull request trigger": "  pull_request:",
    "manual workflow dispatch": "  workflow_dispatch:",
    "weekly scheduled run": "  schedule:",
    "full suite runner": "bash CHECK.sh 2>&1 | tee",
    "failure log upload": "actions/upload-artifact@v7",
    "read-only token permissions": "  contents: read",
    "concurrency cancellation": "  cancel-in-progress: true",
    "bounded runtime": "    timeout-minutes: 30",
}
missing = [name for name, needle in required.items() if needle not in workflow]
if missing:
    raise SystemExit("GitHub Actions workflow is missing: " + ", ".join(missing))
if "tests/test_ci_test_coverage.sh" not in check:
    raise SystemExit("CHECK.sh must run the CI test-coverage guard")
print("GitHub Actions CI workflow wiring: OK")
PY
