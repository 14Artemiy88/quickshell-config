#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin" "$TMP/config" "$TMP/cache/weather" "$TMP/data" "$TMP/state" "$TMP/home"
REAL_JQ="$(command -v jq)"
export REAL_JQ
export JQ_CALL_LOG="$TMP/jq-calls.log"
export CURL_CALL_LOG="$TMP/curl-calls.log"
export HOME="$TMP/home"
# Point migration discovery at an empty project root so the test counts only
# the settings/cache lookups under test, not startup migration probes.
mkdir -p "$TMP/project"
export QS_PROJECT_DIR="$TMP/project"
export QS_CONFIG_DIR="$TMP/config"
export QS_DATA_DIR="$TMP/data"
export QS_STATE_DIR="$TMP/state"
export QS_CACHE_DIR="$TMP/cache"
export PATH="$TMP/bin:$PATH"

cat > "$TMP/bin/jq" <<'MOCK_JQ'
#!/usr/bin/env bash
printf 'call ' >> "$JQ_CALL_LOG"
printf '%q ' "$@" >> "$JQ_CALL_LOG"
printf '\n' >> "$JQ_CALL_LOG"
exec "$REAL_JQ" "$@"
MOCK_JQ
cat > "$TMP/bin/curl" <<'MOCK_CURL'
#!/usr/bin/env bash
printf 'curl\n' >> "$CURL_CALL_LOG"
exit 7
MOCK_CURL
chmod +x "$TMP/bin/jq" "$TMP/bin/curl"

CACHE="$TMP/cache/weather/now_.json"
printf '%s\n' '{"temperature":19,"summary":"cached only"}' > "$CACHE"

# A fresh cache must be usable even when settings/token are unavailable. The
# cache read itself should require one jq process, not cat + jq + token jq.
: > "$JQ_CALL_LOG"
"$ROOT/scripts/weather" now > "$TMP/fresh.json"
[[ ! -s "$CURL_CALL_LOG" ]]
[[ "$(wc -l < "$JQ_CALL_LOG")" -eq 1 ]]
if grep -Fq "$QS_CONFIG_DIR/settings.json" "$JQ_CALL_LOG"; then
    echo 'fresh weather cache unexpectedly read settings/token' >&2
    exit 1
fi
jq -e '.temperature == 19 and .summary == "cached only"' "$TMP/fresh.json" >/dev/null

# The cached reader must reject more than one JSON document.
printf '%s\n%s\n' '{"temperature":19}' '{"temperature":20}' > "$CACHE"
touch "$CACHE"
if "$ROOT/scripts/weather" now > "$TMP/multidoc.json" 2>/dev/null; then
    echo 'multiple JSON documents were accepted as one weather cache' >&2
    exit 1
fi
[[ ! -s "$TMP/multidoc.json" ]]

# A usable stale cache remains a fallback even if settings/token are missing.
printf '%s\n' '{"temperature":17,"summary":"stale without token"}' > "$CACHE"
touch -d '2 minutes ago' "$CACHE"
: > "$JQ_CALL_LOG"
: > "$CURL_CALL_LOG"
WEATHER_CACHE_TTL=1 "$ROOT/scripts/weather" now > "$TMP/stale.json" 2>"$TMP/stale.err"
jq -e '.temperature == 17 and .summary == "stale without token"' "$TMP/stale.json" >/dev/null
[[ ! -s "$CURL_CALL_LOG" ]]

# Existing token-driven refresh/fallback coverage remains in the older tests.
echo 'Weather cache hot-path test: OK'
