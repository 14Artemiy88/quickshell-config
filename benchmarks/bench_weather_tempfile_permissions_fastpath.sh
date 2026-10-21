#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
mkdir -p "$TMP/config" "$TMP/data" "$TMP/state" "$TMP/cache/weather" "$TMP/home"
printf '%s\n' '{"weatherToken":"bench-token"}' > "$TMP/config/settings.json"
: > "$TMP/config/.migration-settings-v1"
: > "$TMP/data/.migration-calendar-notes-v1"
export HOME="$TMP/home" QS_PROJECT_DIR="$ROOT" QS_CONFIG_DIR="$TMP/config" QS_DATA_DIR="$TMP/data" QS_STATE_DIR="$TMP/state" QS_CACHE_DIR="$TMP/cache"
source "$ROOT/scripts/weather.d/common.sh"

ITERATIONS="${1:-100}"
[[ "$ITERATIONS" =~ ^[0-9]+$ ]] && (( ITERATIONS >= 1 && ITERATIONS <= 10000 )) || { echo 'usage: bench_weather_tempfile_permissions_fastpath.sh [iterations 1..10000]' >&2; exit 2; }

before_pair() {
    local i tmp target
    for ((i=0; i<ITERATIONS; i++)); do
        target="$TMP/cache/weather/before-cache.json"
        tmp="$(mktemp "${target}.XXXXXX")"
        printf '{"i":%s}\n' "$i" > "$tmp"
        chmod 600 "$tmp"
        mv -f -- "$tmp" "$target"
        target="$TMP/cache/weather/before-attempt"
        tmp="$(mktemp "${target}.XXXXXX")"
        printf '%s\n' "$i" > "$tmp"
        chmod 600 "$tmp"
        mv -f -- "$tmp" "$target"
    done
}

after_pair() {
    local i
    for ((i=0; i<ITERATIONS; i++)); do
        weather_cache_write "$TMP/cache/weather/after-cache.json" "{\"i\":$i}"
        weather_mark_attempt "$TMP/cache/weather/after-attempt" "$i"
    done
}

measure_ns() {
    local name="$1"; shift
    local start end elapsed
    start="$(date +%s%N)"
    "$@"
    end="$(date +%s%N)"
    elapsed=$((end - start))
    printf '%s %s\n' "$name" "$elapsed"
}

before=(); after=()
for trial in 1 2 3 4 5; do
    before+=("$(measure_ns before before_pair | awk '{print $2}')")
    after+=("$(measure_ns after after_pair | awk '{print $2}')")
done
sort_values() { printf '%s\n' "$@" | sort -n; }
before_median="$(sort_values "${before[@]}" | sed -n '3p')"
after_median="$(sort_values "${after[@]}" | sed -n '3p')"
printf 'iterations=%s cache+attempt pairs per trial\n' "$ITERATIONS"
printf 'before_median_ms=%.3f\n' "$(awk -v n="$before_median" 'BEGIN {print n/1000000}')"
printf 'after_median_ms=%.3f\n' "$(awk -v n="$after_median" 'BEGIN {print n/1000000}')"
printf 'chmod_calls_before=%s\n' "$((ITERATIONS * 2))"
printf 'chmod_calls_after=0\n'
printf 'scope=cache/attempt temp-file publication only; filesystem and mv/mktemp costs remain included\n'
