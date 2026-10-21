#!/usr/bin/env bash
# Model the old two-command vs new one-command DeaDBeeF metadata fetch.
# Usage: benchmarks/bench_deadbeef_single_metadata_call.sh [polls=100] [trials=5]
set -euo pipefail
polls="${1:-100}"
trials="${2:-5}"
[[ "$polls" =~ ^[1-9][0-9]*$ && "$trials" =~ ^[1-9][0-9]*$ ]] || {
    echo "Usage: $0 [polls=100] [trials=5]" >&2
    exit 2
}
work="$(mktemp -d)"
trap 'rm -rf -- "$work"' EXIT
mkdir -p "$work/bin"
cat > "$work/bin/deadbeef" <<'STUB'
#!/usr/bin/env bash
case "${1:-}" in
    --nowplaying) printf 'Regression Test Track\n' ;;
    --nowplaying-tf)
        if [[ "${2:-}" == *'%title%' ]]; then
            printf '0|Artist|2025|Album|300|12.5|-00:42|/music/track.mp3|Regression Test Track\n'
        else
            printf '0|Artist|2025|Album|300|12.5|-00:42|/music/track.mp3\n'
        fi
        ;;
    *) exit 1 ;;
esac
STUB
chmod +x "$work/bin/deadbeef"
export PATH="$work/bin:$PATH"

python3 - "$polls" "$trials" <<'PY'
import statistics
import subprocess
import sys
import time

polls, trials = map(int, sys.argv[1:])
old_loop = r'''
for ((i=0; i<N; i++)); do
  title=$(deadbeef --nowplaying "%t")
  [[ -n "$title" && "$title" != nothing ]] || continue
  meta=$(deadbeef --nowplaying-tf '$if(%ispaused%,1,0)|%artist%|%year%|%album%|%length_seconds%|%playback_time_seconds%|-%playback_time_remaining%|%path%')
  [[ -n "$meta" ]] || exit 1
 done
'''
new_loop = r'''
for ((i=0; i<N; i++)); do
  meta=$(deadbeef --nowplaying-tf '$if(%ispaused%,1,0)|%artist%|%year%|%album%|%length_seconds%|%playback_time_seconds%|-%playback_time_remaining%|%path%|%title%')
  [[ -n "$meta" ]] || exit 1
 done
'''
def measure(body):
    samples = []
    for _ in range(trials):
        start = time.perf_counter_ns()
        subprocess.run(['bash', '-c', body, 'bench'], env={**__import__('os').environ, 'N': str(polls)},
                       check=True, stdout=subprocess.DEVNULL)
        samples.append((time.perf_counter_ns() - start) / 1_000_000)
    return statistics.median(samples)
old = measure(old_loop)
new = measure(new_loop)
print(f'DeaDBeeF metadata CLI mock ({polls} polls; median of {trials} trials)')
print(f'Before: {2 * polls} CLI launches; {old:.3f} ms')
print(f'After:  {polls} CLI launches; {new:.3f} ms')
print(f'CLI launches removed: {polls} ({50.0:.1f}%); measured mock-path time change: {(old-new)/old*100:.1f}%')
print('Stub-based benchmark only; real DeaDBeeF response/startup latency may differ.')
PY
