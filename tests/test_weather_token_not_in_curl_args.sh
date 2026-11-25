#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
mkdir -p "$TMP/bin" "$TMP/config" "$TMP/data" "$TMP/state" "$TMP/cache" "$TMP/home"
export HOME="$TMP/home" QS_PROJECT_DIR="$ROOT" QS_CONFIG_DIR="$TMP/config"
export QS_DATA_DIR="$TMP/data" QS_STATE_DIR="$TMP/state" QS_CACHE_DIR="$TMP/cache"
export CURL_ARGS_LOG="$TMP/curl-args.log" CURL_HEADER_LOG="$TMP/curl-header.log"
export WEATHER_CURL_OUTPUT='{"response":{"temperature":23,"summary":"token transport"}}'
: > "$CURL_ARGS_LOG"
: > "$CURL_HEADER_LOG"

cat > "$TMP/bin/curl" <<'CURL'
#!/usr/bin/env bash
printf '%s\n' "$*" > "$CURL_ARGS_LOG"
header_mode=false
for arg in "$@"; do
    if [[ "$header_mode" == true ]]; then
        [[ "$arg" == '@-' ]] || exit 90
        IFS= read -r header || exit 91
        printf '%s\n' "$header" > "$CURL_HEADER_LOG"
        header_mode=false
    elif [[ "$arg" == '--header' ]]; then
        header_mode=true
    fi
done
[[ "$header_mode" == false ]] || exit 92
printf '%s\n' "$WEATHER_CURL_OUTPUT"
CURL
chmod +x "$TMP/bin/curl"
export PATH="$TMP/bin:$PATH"

SECRET='secret-token-must-not-be-in-argv-7f31'
printf '{"weatherToken":"%s"}\n' "$SECRET" > "$QS_CONFIG_DIR/secrets.json"
"$ROOT/scripts/weather" now > "$TMP/output.json"
jq -e '.temperature == 23 and .summary == "token transport"' "$TMP/output.json" >/dev/null
[[ "$(<"$CURL_HEADER_LOG")" == "X-Gismeteo-Token: $SECRET" ]] || {
    echo 'curl did not receive the expected token header through stdin' >&2; exit 1;
}
if grep -Fq -- "$SECRET" "$CURL_ARGS_LOG"; then
    echo 'weather token leaked into curl process arguments' >&2; exit 1
fi
[[ "$(<"$CURL_ARGS_LOG")" == *'--header @-'* ]] || {
    echo 'curl did not use stdin-backed header input' >&2; exit 1;
}

# Reject every ASCII control character in escaped JSON tokens before raw
# output. This covers CR/LF header injection, tabs, NUL (unsafe in Bash
# command substitutions), ESC, and DEL. No curl request may be started.
for escaped_control in '\r' '\n' '\t' '\u001b' '\u007f' '\u0000'; do
    printf '{"weatherToken":"invalid%s-token"}\n' "$escaped_control" > "$QS_CONFIG_DIR/secrets.json"
    rm -f "$CURL_ARGS_LOG" "$CURL_HEADER_LOG"
    if "$ROOT/scripts/weather" now --force > "$TMP/invalid-output.json" 2> "$TMP/invalid-error.log"; then
        printf 'control-character token was accepted: %q\n' "$escaped_control" >&2
        exit 1
    fi
    [[ ! -s "$CURL_ARGS_LOG" ]] || { echo 'curl ran with an invalid token' >&2; exit 1; }
    [[ ! -s "$CURL_HEADER_LOG" ]] || { echo 'invalid token reached curl stdin' >&2; exit 1; }
    [[ ! -s "$TMP/invalid-output.json" ]] || { echo 'invalid token produced weather output' >&2; exit 1; }
done

echo 'Weather token stdin transport: token absent from curl argv; all ASCII control characters rejected: OK'
