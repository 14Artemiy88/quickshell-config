#!/usr/bin/env bash
set -euo pipefail
# Compare the old two-filter CAVA stream with the single AWK filter now in
# scripts/cava. Print only medians; do not create CSV/graph artifacts.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LINES="${LINES:-20000}"
TRIALS="${TRIALS:-5}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

python3 - "$LINES" "$TMP/input" <<'PY'
from pathlib import Path
import sys
lines = int(sys.argv[1])
Path(sys.argv[2]).write_text(''.join(f'{i % 100};{(i + 1) % 100};{(i + 2) % 100};\n' for i in range(lines)))
PY

python3 - "$TMP/input" "$LINES" "$TRIALS" <<'PY'
import statistics
import subprocess
import sys
import time

input_path, line_count, trials = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
commands = {
    'before (sed + awk)': "sed -u 's/;$//; s/;/,/g' | awk '{print \"[\" $0 \"]\"; fflush()}'",
    'after (awk only)': "awk '{ sub(/;$/, \"\"); gsub(/;/, \",\"); print \"[\" $0 \"]\"; fflush() }'",
}
results = {}
for label, command in commands.items():
    values = []
    for _ in range(trials):
        with open(input_path, 'rb') as source:
            start = time.perf_counter_ns()
            subprocess.run(['bash', '-c', command], stdin=source, stdout=subprocess.DEVNULL, check=True)
            values.append((time.perf_counter_ns() - start) / 1_000_000)
    results[label] = statistics.median(values)
    print(f'{label}: median {results[label]:.3f} ms over {trials} trials')
print(f'Lines per trial: {line_count}')
print('Filter processes per CAVA stream: 2 -> 1')
PY
