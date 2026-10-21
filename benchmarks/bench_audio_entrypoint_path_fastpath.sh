#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_PATH="$ROOT/scripts/get_volume"
N="${1:-100}"
[[ "$N" =~ ^[0-9]+$ ]] && (( N > 0 )) || { echo "Usage: $0 [iterations]" >&2; exit 2; }

python3 - "$SCRIPT_PATH" "$N" <<'PY'
import statistics
import subprocess
import sys
import time

script_path, count_text = sys.argv[1:]
count = int(count_text)
old_code = r'''
path="$1"; n="$2"
for ((i=0; i<n; i++)); do
  dir="$(cd -- "$(dirname -- "$path")" && pwd)"
  [[ -n "$dir" ]] || exit 1
done
'''
new_code = r'''
path="$1"; n="$2"
for ((i=0; i<n; i++)); do
  dir="${path%/*}"
  [[ "$dir" != "$path" ]] || dir=.
  [[ -n "$dir" ]] || exit 1
done
'''
def measure(code):
    start = time.perf_counter()
    subprocess.run(["bash", "-c", code, "bench", script_path, str(count)], check=True, stdout=subprocess.DEVNULL)
    return (time.perf_counter() - start) * 1000

old = [measure(old_code) for _ in range(5)]
new = [measure(new_code) for _ in range(5)]
print(f"Audio entry-point path setup, {count} iterations (median of 5 trials)")
print(f"Before: dirname launches={count}, median={statistics.median(old):.3f} ms")
print(f"After:  dirname launches=0, median={statistics.median(new):.3f} ms")
PY
