#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
ITERATIONS="${ITERATIONS:-40}"
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
source "$ROOT/scripts/system_monitor.d/top_apps.sh"

CPU_ROWS=$'zen\t17.3750\t7\t101\nfirefox\t12.1250\t5\t202\ngoland\t4.0000\t3\t303'
MEM_ROWS=$'firefox\t1048576\t5\t202\nzen\t524288\t7\t101\ngoland\t262144\t3\t303'
CPU_CAPACITY='800.0000'
MEM_CAPACITY='16384000'

# Baseline path used by v772: encode CPU and RAM separately, then combine them.
run_before() {
    local cpu_json mem_json
    cpu_json="$(format_top_apps_rows_json "$CPU_ROWS" cpu "$CPU_CAPACITY")"
    mem_json="$(format_top_apps_rows_json "$MEM_ROWS" mem "$MEM_CAPACITY")"
    jq -cn --argjson cpu "$cpu_json" --argjson mem "$mem_json" '{cpu:$cpu,mem:$mem}'
}

# Optimized path: format both sections as TSV and perform one final JSON encode.
run_after() {
    local cpu_tsv mem_tsv
    cpu_tsv="$(format_top_apps_rows_tsv "$CPU_ROWS" cpu "$CPU_CAPACITY")"
    mem_tsv="$(format_top_apps_rows_tsv "$MEM_ROWS" mem "$MEM_CAPACITY")"
    format_top_apps_payload_json "$cpu_tsv" "$mem_tsv"
}

before_sample="$(run_before)"
after_sample="$(run_after)"
[[ "$before_sample" == "$after_sample" ]] || {
    printf 'Before/after JSON differs\nbefore=%s\nafter =%s\n' "$before_sample" "$after_sample" >&2
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
    : > "$BENCH_JQ_LOG"
    for ((trial=0; trial<5; trial++)); do
        : > "$BENCH_JQ_LOG"
        clock_us; start=$CLOCK_US
        for ((i=0; i<ITERATIONS; i++)); do
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
    printf '%s: polls/trial=%s, jq/trial=%s, median=%s us\n' "$label" "$ITERATIONS" "$jq_calls" "${sorted[2]}"
}
run_side before
run_side after
printf 'Per combined poll: jq 3 -> 1; JSON output parity: OK\n'
