#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/cache/weather" "$TMP/config" "$TMP/data" "$TMP/state" "$TMP/home"
export HOME="$TMP/home"
export QS_PROJECT_DIR="$ROOT"
export QS_CONFIG_DIR="$TMP/config"
export QS_DATA_DIR="$TMP/data"
export QS_STATE_DIR="$TMP/state"
export QS_CACHE_DIR="$TMP/cache"
export WEATHER_TTL_PWN="$TMP/ttl-command-ran"

# A malformed value containing command substitution must be rejected before
# it can reach ((...)); the same is true for both cache and retry TTLs.
export WEATHER_CACHE_TTL='x[$(touch "$WEATHER_TTL_PWN")]'
export WEATHER_ERROR_RETRY_TTL='x[$(touch "$WEATHER_TTL_PWN")]'
source "$ROOT/scripts/weather.d/common.sh"
[[ "$WEATHER_CACHE_TTL" == 600 ]] || {
    echo "malformed cache TTL did not fall back to 600: $WEATHER_CACHE_TTL" >&2
    exit 1
}
[[ "$WEATHER_ERROR_RETRY_TTL" == 30 ]] || {
    echo "malformed retry TTL did not fall back to 30: $WEATHER_ERROR_RETRY_TTL" >&2
    exit 1
}

CACHE="$TMP/cache/weather/fresh.json"
printf '%s\n' '{"temperature":18}' > "$CACHE"
touch "$CACHE"
weather_cache_valid "$CACHE" || {
    echo 'default cache TTL rejected a fresh cache' >&2
    exit 1
}

ATTEMPT="$TMP/cache/weather/recent.attempt"
printf '%s\n' "$EPOCHSECONDS" > "$ATTEMPT"
weather_attempt_recent "$ATTEMPT" "$EPOCHSECONDS" || {
    echo 'default retry TTL rejected a recent attempt' >&2
    exit 1
}
[[ ! -e "$WEATHER_TTL_PWN" ]] || {
    echo 'malformed TTL environment value executed command substitution' >&2
    exit 1
}

# Numeric settings are normalized as decimal (not octal) and remain usable.
env WEATHER_CACHE_TTL=0000000008 WEATHER_ERROR_RETRY_TTL=0000000004 bash -c '
    source "$QS_PROJECT_DIR/scripts/weather.d/common.sh"
    [[ "$WEATHER_CACHE_TTL" == 8 && "$WEATHER_ERROR_RETRY_TTL" == 4 ]]
' || {
    echo 'valid leading-zero decimal TTL values were not normalized' >&2
    exit 1
}

# Values beyond the supported signed 32-bit duration range use safe defaults.
env WEATHER_CACHE_TTL=9999999999 WEATHER_ERROR_RETRY_TTL=9999999999 bash -c '
    source "$QS_PROJECT_DIR/scripts/weather.d/common.sh"
    [[ "$WEATHER_CACHE_TTL" == 600 && "$WEATHER_ERROR_RETRY_TTL" == 30 ]]
' || {
    echo 'out-of-range TTL values did not fall back to defaults' >&2
    exit 1
}

printf 'Weather TTL environment validation: safe numeric normalization, no arithmetic evaluation of untrusted strings: OK\n'
