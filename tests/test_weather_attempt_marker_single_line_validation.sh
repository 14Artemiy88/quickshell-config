#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
mkdir -p "$TMP/config" "$TMP/data" "$TMP/state" "$TMP/cache" "$TMP/home"
export HOME="$TMP/home" QS_PROJECT_DIR="$ROOT" QS_CONFIG_DIR="$TMP/config"
export QS_DATA_DIR="$TMP/data" QS_STATE_DIR="$TMP/state" QS_CACHE_DIR="$TMP/cache"
source "$ROOT/scripts/weather.d/common.sh"
ATTEMPT="$TMP/cache/weather/recent.attempt"
mkdir -p "${ATTEMPT%/*}"

# The writer's canonical representation is one decimal line with a newline.
weather_mark_attempt "$ATTEMPT" 1234567890
weather_attempt_recent "$ATTEMPT" 1234567891 || {
    echo 'canonical single-line marker was rejected' >&2
    exit 1
}

# The signed 64-bit maximum is the largest valid timestamp: 19 digits plus LF.
weather_mark_attempt "$ATTEMPT" 9223372036854775807
[[ "$(stat -c %s -- "$ATTEMPT")" == 20 ]] || {
    echo 'maximum valid timestamp did not produce the canonical 20-byte marker' >&2
    exit 1
}
weather_attempt_recent "$ATTEMPT" 9223372036854775807 || {
    echo 'maximum signed 64-bit timestamp was rejected' >&2
    exit 1
}

expect_rejected() {
    local description="$1" contents="$2"
    printf '%s' "$contents" > "$ATTEMPT"
    if weather_attempt_recent "$ATTEMPT" 1234567891; then
        printf 'malformed attempt marker was accepted: %s\n' "$description" >&2
        exit 1
    fi
}

expect_rejected 'valid timestamp followed by junk line' $'1234567890\njunk\n'
expect_rejected 'valid timestamp followed by a blank line' $'1234567890\n\n'
expect_rejected 'valid timestamp followed by a second timestamp' $'1234567890\n1234567890\n'
expect_rejected 'timestamp with trailing spaces' '1234567890  \n'
expect_rejected 'timestamp with carriage return' $'1234567890\r\n'
expect_rejected 'missing canonical newline' '1234567890'
expect_rejected 'empty marker' ''
expect_rejected 'timestamp above signed 64-bit maximum' $'9223372036854775808\n'
expect_rejected '20-digit timestamp beyond the signed 64-bit width' $'10000000000000000000\n'
printf '1234567890\n\0' > "$ATTEMPT"
if weather_attempt_recent "$ATTEMPT" 1234567891; then
    echo 'NUL byte after timestamp was accepted' >&2
    exit 1
fi
printf '1234567890\0\n' > "$ATTEMPT"
if weather_attempt_recent "$ATTEMPT" 1234567891; then
    echo 'NUL byte inside timestamp line was accepted' >&2
    exit 1
fi
expect_rejected 'oversized marker' "$(printf '%070d\n' 1)"

# Malformed content must not be interpreted as a recent attempt or arithmetic.
PWN="$TMP/attempt-command-ran"
export WEATHER_ATTEMPT_PWN="$PWN"
expect_rejected 'command substitution payload' '123[$(touch "$WEATHER_ATTEMPT_PWN")]'
[[ ! -e "$PWN" ]] || {
    echo 'malformed marker executed command substitution' >&2
    exit 1
}

# A failed parse closes its descriptor and does not poison a later valid read.
weather_mark_attempt "$ATTEMPT" 00008
weather_attempt_recent "$ATTEMPT" 00009 || {
    echo 'valid marker failed after a malformed-marker read' >&2
    exit 1
}

echo 'Weather attempt marker single-line validation: exact one-line format and safe retry parsing: OK'
