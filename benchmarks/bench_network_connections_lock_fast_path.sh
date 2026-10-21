#!/usr/bin/env bash
# Compare the v768 always-lock cache-hit path with v769's pre-lock fresh-cache
# path. The cache is intentionally fresh so this isolates per-poll overhead,
# not nmcli/JSON parsing or real network latency.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/system_monitor.d/network_connections.sh"

iterations="${1:-200}"
trials="${2:-5}"
[[ "$iterations" =~ ^[1-9][0-9]*$ && "$trials" =~ ^[1-9][0-9]*$ ]] || {
    echo "Usage: $0 [cached_requests=200] [trials=5]" >&2
    exit 2
}
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin"
REAL_FLOCK="$(command -v flock)"
cat > "$TMP/bin/flock" <<'WRAPPER'
#!/usr/bin/env bash
printf 'flock\n' >> "$PROCESS_LOG"
exec "$REAL_FLOCK" "$@"
WRAPPER
chmod +x "$TMP/bin/flock"
PROCESS_LOG="$TMP/processes.log"
: > "$PROCESS_LOG"
export PROCESS_LOG REAL_FLOCK
PATH="$TMP/bin:$PATH"
export PATH

cache="$TMP/cache.json"
cache_time="$TMP/cache-time"
printf '%s\n' '[]' > "$cache"
printf '%s\n' "$(( ${EPOCHSECONDS:-0} + 60 ))" > "$cache_time"

# Baseline equivalent of v768: always create a subshell and lock before the
# helper discovers that the cache is still fresh.
get_network_connections_before() {
    local cache_file="${1:-}" cache_time_file="${2:-}"
    if command -v flock >/dev/null 2>&1 && [[ -n "$cache_file" ]]; then
        (
            umask 077
            exec 9>"${cache_file}.lock" || exit 1
            flock -x 9 || exit 1
            _get_network_connections_unlocked "$cache_file" "$cache_time_file"
        )
    else
        _get_network_connections_unlocked "$cache_file" "$cache_time_file"
    fi
}
now_us() {
    local stamp seconds fraction
    stamp="$EPOCHREALTIME"
    seconds="${stamp%.*}"
    fraction="${stamp#*.}000000"
    fraction="${fraction:0:6}"
    printf '%s' "$((10#$seconds * 1000000 + 10#$fraction))"
}
measure() {
    local variant="$1" trial i start end elapsed calls
    local -a samples=()
    for ((trial=0; trial<trials; trial++)); do
        : > "$PROCESS_LOG"
        start="$(now_us)"
        for ((i=0; i<iterations; i++)); do
            if [[ "$variant" == before ]]; then
                get_network_connections_before "$cache" "$cache_time" >/dev/null
            else
                get_network_connections "$cache" "$cache_time" >/dev/null
            fi
        done
        end="$(now_us)"
        elapsed=$((end-start))
        calls="$(grep -c '^flock$' "$PROCESS_LOG" || true)"
        samples+=("$elapsed:$calls")
    done
    printf '%s\n' "${samples[@]}" | sort -t: -k1,1n > "$TMP/sorted"
    local median_line
    median_line="$(sed -n "$(( (trials + 1) / 2 ))p" "$TMP/sorted")"
    printf '%s\t%s\n' "${median_line%%:*}" "${median_line#*:}"
}

before_result="$(measure before)"
after_result="$(measure after)"
IFS=$'\t' read -r before_us before_calls <<< "$before_result"
IFS=$'\t' read -r after_us after_calls <<< "$after_result"
printf 'System Monitor fresh-cache path (%s cache hits, median of %s trials)\n' "$iterations" "$trials"
printf 'before_flock_calls=%s\nafter_flock_calls=%s\n' "$before_calls" "$after_calls"
printf 'before_us=%s\nafter_us=%s\n' "$before_us" "$after_us"
if (( 10#$before_us > 0 )); then
    awk -v b="$before_us" -v a="$after_us" 'BEGIN { printf "time_reduction_pct=%.1f%%\n", (b-a)*100/b }'
fi
