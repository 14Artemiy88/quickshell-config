#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
mkdir -p "$TMP/bin" "$TMP/before" "$TMP/after"
REAL_JQ="$(command -v jq)"
export REAL_JQ
cat > "$TMP/bin/jq" <<'WRAP_JQ'
#!/usr/bin/env bash
printf 'x\n' >> "$COUNT_DIR/jq"
exec "$REAL_JQ" "$@"
WRAP_JQ
cat > "$TMP/bin/curl" <<'WRAP_CURL'
#!/usr/bin/env bash
set -euo pipefail
printf 'x\n' >> "$COUNT_DIR/curl"
body=''
while (($#)); do
    case "$1" in
        -d) body="${2:-}"; shift 2 ;;
        *) shift ;;
    esac
done
if [[ "$body" == *'core.mixer.get_volume'* && "$body" == *'core.mixer.get_mute'* ]]; then
    printf '[{"jsonrpc":"2.0","id":2,"result":false},{"jsonrpc":"2.0","id":1,"result":64}]\n'
elif [[ "$body" == *'core.mixer.get_volume'* ]]; then
    printf '{"jsonrpc":"2.0","id":1,"result":64}\n'
elif [[ "$body" == *'core.mixer.get_mute'* ]]; then
    printf '{"jsonrpc":"2.0","id":1,"result":false}\n'
else
    exit 2
fi
WRAP_CURL
chmod +x "$TMP/bin/jq" "$TMP/bin/curl"

clock_us() {
    local raw="$EPOCHREALTIME" sec fraction
    sec="${raw%%.*}"
    fraction="${raw#*.}000000"
    fraction="${fraction:0:6}"
    CLOCK_US=$((10#$sec * 1000000 + 10#$fraction))
}
count_lines() {
    local file="$1" count=0 ignored
    [[ -f "$file" ]] || { printf '0'; return; }
    while IFS= read -r ignored; do ((count+=1)); done < "$file"
    printf '%s' "$count"
}
run_case() {
    local label="$1" script="$2" counter_dir="$3" trial start finish elapsed iteration
    local jq_count curl_count
    local -a samples=() sorted=()
    export COUNT_DIR="$counter_dir" MOPIDY_RPC_URL='http://mock.invalid/mopidy/rpc'
    for ((trial=0; trial<5; trial++)); do
        : > "$counter_dir/curl"; : > "$counter_dir/jq"
        clock_us; start=$CLOCK_US
        for ((iteration=0; iteration<40; iteration++)); do
            PATH="$TMP/bin:$PATH" bash "$script" get >/dev/null
        done
        clock_us; finish=$CLOCK_US
        samples+=("$((finish - start))")
        jq_count="$(count_lines "$counter_dir/jq")"
        curl_count="$(count_lines "$counter_dir/curl")"
    done
    sorted=("${samples[@]}")
    # Five values only: sort in Bash so the benchmark doesn't need an external
    # sort process that would muddy the process-count comparison.
    local i j temp
    for ((i=0; i<${#sorted[@]}; i++)); do
        for ((j=i+1; j<${#sorted[@]}; j++)); do
            if (( sorted[j] < sorted[i] )); then
                temp="${sorted[i]}"; sorted[i]="${sorted[j]}"; sorted[j]="$temp"
            fi
        done
    done
    printf '%s: polls/trial=40, trials=5, curl/trial=%s, jq/trial=%s, median=%s us\n' \
        "$label" "$curl_count" "$jq_count" "${sorted[2]}"
}

run_case before "$ROOT/benchmarks/fixtures/v771_mopidy_mixer.sh" "$TMP/before"
run_case after "$ROOT/scripts/mopidy/mixer.sh" "$TMP/after"
