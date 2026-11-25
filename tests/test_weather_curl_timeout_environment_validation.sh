#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
mkdir -p "$TMP/bin" "$TMP/config" "$TMP/data" "$TMP/state" "$TMP/cache" "$TMP/home"
export HOME="$TMP/home" QS_PROJECT_DIR="$ROOT" QS_CONFIG_DIR="$TMP/config"
export QS_DATA_DIR="$TMP/data" QS_STATE_DIR="$TMP/state" QS_CACHE_DIR="$TMP/cache"
export CURL_ARGS_LOG="$TMP/curl-args.log" CURL_HEADER_LOG="$TMP/curl-header.log"
export CURL_TIMEOUT_PWN="$TMP/timeout-command-ran"
printf '%s\n' '{"weatherToken":"curl-timeout-test-token"}' > "$QS_CONFIG_DIR/secrets.json"

cat > "$TMP/bin/curl" <<'CURL'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$CURL_ARGS_LOG"
while (($#)); do
    if [[ "$1" == '--header' ]]; then
        [[ "${2:-}" == '@-' ]] || exit 90
        IFS= read -r header || exit 91
        printf '%s\n' "$header" > "$CURL_HEADER_LOG"
        break
    fi
    shift
done
printf '%s\n' '{"response":{"temperature":21}}'
CURL
chmod +x "$TMP/bin/curl"
export PATH="$TMP/bin:$PATH"

run_case() {
    local connect="$1" max="$2" expected_connect="$3" expected_max="$4" label="$5"
    rm -f "$CURL_ARGS_LOG" "$CURL_HEADER_LOG" "$TMP/cache/weather/now_.json" \
        "$TMP/cache/weather/now_.json.lock" "$TMP/cache/weather/now_.json.attempt"
    WEATHER_CURL_CONNECT_TIMEOUT="$connect" WEATHER_CURL_MAX_TIME="$max" \
        "$ROOT/scripts/weather" now --force > "$TMP/output.json"
    jq -e '.temperature == 21' "$TMP/output.json" >/dev/null
    mapfile -t args < "$CURL_ARGS_LOG"
    local actual_connect='' actual_max='' i
    for ((i=0; i<${#args[@]}; i++)); do
        case "${args[$i]}" in
            --connect-timeout) actual_connect="${args[$((i+1))]:-}" ;;
            --max-time) actual_max="${args[$((i+1))]:-}" ;;
        esac
    done
    [[ "$actual_connect" == "$expected_connect" ]] || {
        printf '%s: expected connect timeout %s, got %s\n' "$label" "$expected_connect" "$actual_connect" >&2; exit 1;
    }
    [[ "$actual_max" == "$expected_max" ]] || {
        printf '%s: expected max timeout %s, got %s\n' "$label" "$expected_max" "$actual_max" >&2; exit 1;
    }
}

run_case '5' '10' '5' '10' 'defaults'
run_case '0005.500' '010.250' '5.5' '10.25' 'decimal normalization'
run_case '0.125' '120' '0.125' '120' 'positive boundary values'

# Zero, negative, malformed, unbounded, and expression-shaped values must
# fall back without being evaluated or passed through to curl.
for invalid in '0' '0.000' '-1' '+5' '5.' '.5' '1e2' '121' '9999999999' \
    '5.0000' 'abc' '--help' '5;touch "$CURL_TIMEOUT_PWN"' 'x[$(touch "$CURL_TIMEOUT_PWN")]'; do
    run_case "$invalid" "$invalid" '5' '10' "invalid:$invalid"
done
[[ ! -e "$CURL_TIMEOUT_PWN" ]] || {
    echo 'malformed curl timeout environment value executed shell content' >&2
    exit 1
}

# The public, sourced values are also immutable and normalized.
env QS_PROJECT_DIR="$ROOT" QS_CONFIG_DIR="$QS_CONFIG_DIR" QS_DATA_DIR="$QS_DATA_DIR" \
    QS_STATE_DIR="$QS_STATE_DIR" QS_CACHE_DIR="$QS_CACHE_DIR" \
    WEATHER_CURL_CONNECT_TIMEOUT=0007.250 WEATHER_CURL_MAX_TIME=0009 bash -c '
        source "$QS_PROJECT_DIR/scripts/weather.d/common.sh"
        [[ "$WEATHER_CURL_CONNECT_TIMEOUT" == 7.25 && "$WEATHER_CURL_MAX_TIME" == 9 ]]
        ! declare -p WEATHER_CURL_MAX_TIME 2>/dev/null | grep -q "declare --"
    '

echo 'Weather curl timeout environment validation: bounded positive decimals, safe fallback, no evaluation: OK'
