#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
mkdir -p "$TMP/bin" "$TMP/config" "$TMP/data" "$TMP/state" "$TMP/cache" "$TMP/home"

export HOME="$TMP/home"
export QS_PROJECT_DIR="$ROOT"
export QS_CONFIG_DIR="$TMP/config"
export QS_DATA_DIR="$TMP/data"
export QS_STATE_DIR="$TMP/state"
export QS_CACHE_DIR="$TMP/cache"
export WEATHER_SECRET_CURL_LOG="$TMP/curl.log"
export WEATHER_SECRET_HEADER_LOG="$TMP/header.log"
: > "$WEATHER_SECRET_CURL_LOG"
: > "$WEATHER_SECRET_HEADER_LOG"

cat > "$TMP/bin/curl" <<'CURL'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\0' "$@" > "$WEATHER_SECRET_CURL_LOG"
header_mode=false
for arg in "$@"; do
    if [[ "$header_mode" == true ]]; then
        [[ "$arg" == '@-' ]] || exit 90
        IFS= read -r header || exit 91
        printf '%s\n' "$header" > "$WEATHER_SECRET_HEADER_LOG"
        header_mode=false
    elif [[ "$arg" == '--header' ]]; then
        header_mode=true
    fi
done
[[ "$header_mode" == false ]] || exit 92
printf '%s\n' '{"response":{"temperature":22}}'
CURL
chmod +x "$TMP/bin/curl"
export PATH="$TMP/bin:$PATH"

reset_attempt() {
    rm -rf "$QS_CACHE_DIR/weather"
    mkdir -p "$QS_CACHE_DIR/weather"
    : > "$WEATHER_SECRET_CURL_LOG"
    : > "$WEATHER_SECRET_HEADER_LOG"
}

expect_secret_rejected() {
    local description="$1" contents="$2"
    reset_attempt
    printf '%s' "$contents" > "$QS_CONFIG_DIR/secrets.json"
    if "$ROOT/scripts/weather" now --force > "$TMP/out.json" 2> "$TMP/err.log"; then
        printf 'invalid secrets JSON was accepted: %s\n' "$description" >&2
        exit 1
    fi
    [[ ! -s "$WEATHER_SECRET_CURL_LOG" ]] || {
        printf 'curl was started for invalid secrets JSON: %s\n' "$description" >&2
        exit 1
    }
    [[ ! -s "$WEATHER_SECRET_HEADER_LOG" ]] || {
        printf 'token reached curl for invalid secrets JSON: %s\n' "$description" >&2
        exit 1
    }
    [[ ! -s "$TMP/out.json" ]] || {
        printf 'weather output was emitted for invalid secrets JSON: %s\n' "$description" >&2
        exit 1
    }
}

# A valid secrets document may contain ordinary trailing whitespace.
reset_attempt
printf '%s\n\t  ' '{"weatherToken":"single-document-token"}' > "$QS_CONFIG_DIR/secrets.json"
"$ROOT/scripts/weather" now --force > "$TMP/valid.json"
jq -e '.temperature == 22' "$TMP/valid.json" >/dev/null
[[ "$(<"$WEATHER_SECRET_HEADER_LOG")" == 'X-Gismeteo-Token: single-document-token' ]]

# The former streaming jq filter emitted this token before reporting the
# malformed suffix; command-substitution's `|| true` then hid that parse error.
expect_secret_rejected 'valid first object followed by malformed trailing data' \
    '{"weatherToken":"partial-token"} trailing-garbage'
expect_secret_rejected 'two concatenated valid documents' \
    $'{"weatherToken":"first-token"}\n{"weatherToken":"second-token"}'
expect_secret_rejected 'top-level array instead of secrets object' \
    '[{"weatherToken":"array-token"}]'
expect_secret_rejected 'empty secrets file' ''

printf 'Weather secrets single-document validation: OK\n'
