#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
mkdir -p "$TMP/bin" "$TMP/config" "$TMP/data" "$TMP/state" "$TMP/cache" "$TMP/home"
printf '%s\n' '{"weatherToken":"response-size-test-token"}' > "$TMP/config/secrets.json"
export HOME="$TMP/home" QS_PROJECT_DIR="$ROOT" QS_CONFIG_DIR="$TMP/config"
export QS_DATA_DIR="$TMP/data" QS_STATE_DIR="$TMP/state" QS_CACHE_DIR="$TMP/cache"
export WEATHER_CURL_ARGS_LOG="$TMP/curl-args.bin" WEATHER_CURL_URL_LOG="$TMP/curl-url.log"
export WEATHER_CURL_HEADER_LOG="$TMP/curl-header.log"

cat > "$TMP/bin/curl" <<'CURL'
#!/usr/bin/env bash
printf '%s\0' "$@" > "$WEATHER_CURL_ARGS_LOG"
local_header=false
url=''
for arg in "$@"; do
    if [[ "$local_header" == true ]]; then
        [[ "$arg" == '@-' ]] || exit 90
        IFS= read -r header || exit 91
        printf '%s\n' "$header" > "$WEATHER_CURL_HEADER_LOG"
        local_header=false
    elif [[ "$arg" == '--header' ]]; then
        local_header=true
    elif [[ "$arg" == https://api.gismeteo.net/* ]]; then
        url="$arg"
    fi
done
[[ "$local_header" == false && -n "$url" ]] || exit 92
printf '%s\n' "$url" >> "$WEATHER_CURL_URL_LOG"
case "$url" in
    */current/*) printf '%s\n' '{"response":{"temperature":21}}' ;;
    *) printf '%s\n' '{"response":[{"temperature":{"air":{"C":21}}}]}' ;;
esac
CURL
chmod +x "$TMP/bin/curl"
export PATH="$TMP/bin:$PATH"

for endpoint in now day week; do
    rm -f "$WEATHER_CURL_ARGS_LOG" "$WEATHER_CURL_HEADER_LOG"
    "$ROOT/scripts/weather" "$endpoint" --force > "$TMP/$endpoint.json"
    mapfile -d '' -t args < "$WEATHER_CURL_ARGS_LOG"
    limit_count=0
    limit_value=''
    for ((i=0; i<${#args[@]}; i++)); do
        if [[ "${args[$i]}" == '--max-filesize' ]]; then
            ((limit_count += 1))
            limit_value="${args[$((i+1))]:-}"
        fi
    done
    [[ "$limit_count" -eq 1 && "$limit_value" == '4194304' ]] || {
        printf '%s: expected exactly one 4 MiB --max-filesize limit, got count=%s value=%s\n' \
            "$endpoint" "$limit_count" "$limit_value" >&2
        exit 1
    }
    [[ "$(<"$WEATHER_CURL_HEADER_LOG")" == 'X-Gismeteo-Token: response-size-test-token' ]] || {
        echo "$endpoint: token header was not preserved while adding the response limit" >&2
        exit 1
    }
    case "$endpoint" in
        now) jq -e 'type == "object" and .temperature == 21' "$TMP/$endpoint.json" >/dev/null ;;
        *) jq -e 'type == "array" and length == 1' "$TMP/$endpoint.json" >/dev/null ;;
    esac
done

[[ "$(wc -l < "$WEATHER_CURL_URL_LOG" | tr -d ' ')" == 3 ]] || {
    echo 'not all Weather endpoints were exercised' >&2
    exit 1
}

echo 'Weather response size limit: all endpoints pass a fixed 4 MiB curl ceiling before jq parsing: OK'
