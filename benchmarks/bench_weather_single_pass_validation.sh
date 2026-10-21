#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
ITERATIONS="${1:-25}"
[[ "$ITERATIONS" =~ ^[1-9][0-9]*$ ]] || { echo "Usage: $0 [iterations]" >&2; exit 2; }
REAL_JQ="$(command -v jq)"
REAL_CAT="$(command -v cat)"
mkdir -p "$TMP/bin" "$TMP/before" "$TMP/after"
cp -a "$ROOT/scripts" "$TMP/before/"
cp -a "$ROOT/scripts" "$TMP/after/"

# Reconstruct the v764 behavior for an apples-to-apples before measurement.
python3 - "$TMP/before/scripts" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
p = root / "weather.d/gismeteo.sh"
s = p.read_text()
s = s.replace(
    "jq -c '.response | if (type == \"object\" or type == \"array\") then select(length > 0) else empty end'",
    "jq -c '.response | select(. != null)'",
)
p.write_text(s)
p = root / "weather"
s = p.read_text()
s = s.replace(
    '''        # The Gismeteo parser emits only non-empty JSON objects/arrays; an
        # empty payload here means the request or response validation failed.
        if [[ -z "$payload" ]]; then
''',
    '''        if [[ -z "$payload" ]] || ! weather_payload_usable "$payload"; then
''',
)
p.write_text(s)
p = root / "weather.d/common.sh"
s = p.read_text()
s = s.replace(
    '''    # The caller passes a payload already validated by weather_gismeteo_fetch.
    # Avoid starting `cat` and another `jq` merely to re-parse the same bytes;
    # the checked printf plus atomic rename are sufficient for safe publication.
    if [[ ! -s "$tmp_file" ]]; then
        rm -f -- "$tmp_file"
        return 1
    fi
''',
    '''    if ! weather_payload_usable "$(cat -- "$tmp_file")"; then
        rm -f -- "$tmp_file"
        return 1
    fi
''',
)
p.write_text(s)
PY

cat > "$TMP/bin/jq" <<'STUB'
#!/usr/bin/env bash
printf 'jq\n' >> "$WEATHER_JQ_LOG"
exec "$REAL_JQ" "$@"
STUB
cat > "$TMP/bin/cat" <<'STUB'
#!/usr/bin/env bash
printf 'cat\n' >> "$WEATHER_CAT_LOG"
exec "$REAL_CAT" "$@"
STUB
cat > "$TMP/bin/curl" <<'STUB'
#!/usr/bin/env bash
printf 'curl\n' >> "$WEATHER_CURL_LOG"
printf '%s\n' '{"response":{"temperature":21,"summary":"benchmark"}}'
STUB
chmod +x "$TMP/bin/jq" "$TMP/bin/cat" "$TMP/bin/curl"
export PATH="$TMP/bin:$PATH" REAL_JQ REAL_CAT

run_variant() {
    local label="$1" variant_dir="$2" cache_root="$TMP/$1-cache" config_root="$TMP/$1-config" i
    mkdir -p "$cache_root" "$config_root" "$TMP/$1-data" "$TMP/$1-state"
    printf '%s\n' '{"weatherToken":"benchmark-token"}' > "$config_root/settings.json"
    export QS_PROJECT_DIR="$ROOT" QS_CONFIG_DIR="$config_root" QS_DATA_DIR="$TMP/$1-data"
    export QS_STATE_DIR="$TMP/$1-state" QS_CACHE_DIR="$cache_root"
    export WEATHER_JQ_LOG="$TMP/$1-jq.log" WEATHER_CAT_LOG="$TMP/$1-cat.log" WEATHER_CURL_LOG="$TMP/$1-curl.log"
    : > "$WEATHER_JQ_LOG"; : > "$WEATHER_CAT_LOG"; : > "$WEATHER_CURL_LOG"
    for ((i=0; i<ITERATIONS; i++)); do
        WEATHER_CACHE_TTL=600 "$variant_dir/scripts/weather" now --force >/dev/null
    done
}

measure() {
    local label="$1" variant_dir="$2" start end elapsed jq_count cat_count curl_count total
    start="$(date +%s%N)"
    run_variant "$label" "$variant_dir"
    end="$(date +%s%N)"
    elapsed=$(( (end - start) / 1000000 ))
    jq_count="$(wc -l < "$TMP/$label-jq.log")"
    cat_count="$(wc -l < "$TMP/$label-cat.log")"
    curl_count="$(wc -l < "$TMP/$label-curl.log")"
    total=$((jq_count + cat_count + curl_count))
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$label" "$elapsed" "$curl_count" "$jq_count" "$cat_count" "$total"
}

printf 'Weather payload validation/cache write benchmark (%s forced mock refreshes)\n' "$ITERATIONS"
printf 'phase\telapsed_ms\tcurl_calls\tjq_calls\tcat_calls\ttracked_calls_total\n'
measure before "$TMP/before"
measure after "$TMP/after"
