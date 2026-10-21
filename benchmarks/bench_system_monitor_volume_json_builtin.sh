#!/usr/bin/env bash
# Compare previous jq array encoding with the built-in encoder used by get_volumes.
# Usage: benchmarks/bench_system_monitor_volume_json_builtin.sh [iterations=100] [trials=5]
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
iterations="${1:-100}"
trials="${2:-5}"
[[ "$iterations" =~ ^[1-9][0-9]*$ && "$trials" =~ ^[1-9][0-9]*$ ]] || {
    echo "Usage: $0 [iterations=100] [trials=5]" >&2
    exit 2
}
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
mkdir -p "$TMP/bin"
REAL_JQ="$(command -v jq)"
cat > "$TMP/bin/jq" <<'WRAP'
#!/usr/bin/env bash
printf 'jq\n' >> "$BENCH_JQ_LOG"
exec "$BENCH_REAL_JQ" "$@"
WRAP
chmod +x "$TMP/bin/jq"
export BENCH_REAL_JQ="$REAL_JQ" BENCH_JQ_LOG="$TMP/jq.log" PATH="$TMP/bin:$PATH"
source "$ROOT/scripts/system_monitor.d/volumes.sh"

fields=(
  '42' '100' 'Browser "Music" \\ Stream'
  '87' '50' 'Video Player'
  '109' '33.5' $'Capture \001\002\037\177 tab\t quote " slash \\ — 東京 🎵'
)
run_before() {
    jq -cn --args '
        $ARGS.positional as $fields |
        [range(0; (($fields | length) / 3)) as $i |
            {num:$fields[$i * 3], value:$fields[$i * 3 + 1], name:$fields[$i * 3 + 2]}]
    ' -- "${fields[@]}"
}
run_after() { system_monitor_volume_encode_fields "${fields[@]}"; }

before_sample="$(run_before)"
after_sample="$(run_after)"
"$REAL_JQ" -n --argjson before "$before_sample" --argjson after "$after_sample" '$before == $after' | grep -qx true || {
    printf 'Before/after volume JSON differs\nbefore=%s\nafter =%s\n' "$before_sample" "$after_sample" >&2
    exit 1
}

clock_us() {
    local raw="$EPOCHREALTIME" sec fraction
    sec="${raw%%.*}"
    fraction="${raw#*.}000000"
    fraction="${fraction:0:6}"
    CLOCK_US=$((10#$sec * 1000000 + 10#$fraction))
}
count_lines() {
    local file="$1" count=0 line
    [[ -f "$file" ]] || { printf '0'; return; }
    while IFS= read -r line; do ((count+=1)); done < "$file"
    printf '%s' "$count"
}
run_side() {
    local label="$1" start end i jq_calls
    local -a samples=() sorted=()
    for ((trial=0; trial<trials; trial++)); do
        : > "$BENCH_JQ_LOG"
        clock_us; start=$CLOCK_US
        for ((i=0; i<iterations; i++)); do
            if [[ "$label" == before ]]; then run_before >/dev/null; else run_after >/dev/null; fi
        done
        clock_us; end=$CLOCK_US
        samples+=("$((end-start))")
        jq_calls="$(count_lines "$BENCH_JQ_LOG")"
    done
    sorted=("${samples[@]}")
    local i2 j temp
    for ((i2=0; i2<${#sorted[@]}; i2++)); do
        for ((j=i2+1; j<${#sorted[@]}; j++)); do
            if (( sorted[j] < sorted[i2] )); then temp="${sorted[i2]}"; sorted[i2]="${sorted[j]}"; sorted[j]="$temp"; fi
        done
    done
    printf '%s: polls/trial=%s, jq/trial=%s, median=%s us\n' "$label" "$iterations" "$jq_calls" "${sorted[${#sorted[@]}/2]}"
}
run_side before
run_side after
printf 'Volume JSON semantic parity: OK; jq launches per poll: 1 -> 0\n'
printf 'Fixture-backed serialization microbenchmark only; full System Monitor latency depends on pactl/AWK and the final payload assembly.\n'
