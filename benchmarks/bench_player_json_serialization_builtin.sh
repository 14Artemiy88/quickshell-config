#!/usr/bin/env bash
# Compare the previous jq --arg payload serializer with the built-in Bash path.
# Usage: benchmarks/bench_player_json_serialization_builtin.sh [iterations=150] [trials=5]
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
iterations="${1:-150}"
trials="${2:-5}"
[[ "$iterations" =~ ^[1-9][0-9]*$ && "$trials" =~ ^[1-9][0-9]*$ ]] || {
    echo "Usage: $0 [iterations=150] [trials=5]" >&2
    exit 2
}

python3 - "$ROOT" "$iterations" "$trials" <<'PY'
import os
import statistics
import subprocess
import sys
import time

root, iterations, trials = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
env = {**os.environ, "N": str(iterations), "PLAYER_COMMON": os.path.join(root, "scripts/player.d/common.sh")}

before = r'''
for ((i=0; i<N; i++)); do
  jq -n \
    --arg first_line 'A "quoted" title \\ path — 東京 🎵' \
    --arg second_line $'Artist\nSecond line' \
    --arg third_line '' \
    --arg timeleft '-00:42' \
    --arg position '25' \
    --arg status '' \
    --arg image '/tmp/cover path.png' \
    --arg text 'Artist\nSecond line' \
    --arg player 'spotify' \
    --arg title_class 'default' \
    --arg duration '120000' \
    '{first_line:$first_line,second_line:$second_line,third_line:$third_line,timeleft:$timeleft,position:$position,status:$status,image:$image,text:$text,player:$player,title_class:$title_class,duration:$duration}' >/dev/null
done
'''
after = r'''
source "$PLAYER_COMMON"
for ((i=0; i<N; i++)); do
  player_build_json_into payload \
    'A "quoted" title \\ path — 東京 🎵' \
    $'Artist\nSecond line' '' '-00:42' '25' '' '/tmp/cover path.png' \
    $'Artist\nSecond line' 'spotify' 'default' '120000'
done
'''

def measure(script):
    samples = []
    for _ in range(trials):
        start = time.perf_counter_ns()
        subprocess.run(["bash", "-c", script], env=env, stdout=subprocess.DEVNULL, check=True)
        samples.append((time.perf_counter_ns() - start) / 1_000_000)
    return statistics.median(samples)

old_ms = measure(before)
new_ms = measure(after)
old_calls, new_calls = iterations, 0
print(f"Player JSON serialization ({iterations} payloads; median of {trials} trials)")
print(f"Before: {old_calls} jq launches; {old_ms:.3f} ms")
print(f"After:  {new_calls} jq launches; {new_ms:.3f} ms")
print(f"jq launches removed: {old_calls - new_calls} ({100.0:.1f}%); measured serializer-path time change: {(old_ms-new_ms)/old_ms*100.0:.1f}%")
print("Fixture-backed microbenchmark only; this isolates serialization and does not measure total Player/widget latency.")
PY
