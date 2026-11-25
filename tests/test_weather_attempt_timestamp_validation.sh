#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
mkdir -p "$TMP/cache/weather" "$TMP/config" "$TMP/data" "$TMP/state" "$TMP/home"
export HOME="$TMP/home" QS_PROJECT_DIR="$ROOT" QS_CONFIG_DIR="$TMP/config" QS_DATA_DIR="$TMP/data" QS_STATE_DIR="$TMP/state" QS_CACHE_DIR="$TMP/cache"
source "$ROOT/scripts/weather.d/common.sh"
ATTEMPT="$TMP/cache/weather/recent.attempt"

# Leading zeroes are decimal, not octal, and writers persist the canonical form.
weather_mark_attempt "$ATTEMPT" 00008 || { echo 'leading-zero timestamp write failed' >&2; exit 1; }
[[ "$(<"$ATTEMPT")" == 8 ]] || { echo "timestamp was not normalized: $(<"$ATTEMPT")" >&2; exit 1; }
weather_attempt_recent "$ATTEMPT" 00008 || { echo 'normalized leading-zero timestamp was not recent' >&2; exit 1; }
printf '%s\n' 00008 > "$ATTEMPT"
weather_attempt_recent "$ATTEMPT" 8 || { echo 'leading-zero marker file was not normalized' >&2; exit 1; }

# Values at the signed 64-bit boundary are safe; the first value above it is rejected.
weather_mark_attempt "$ATTEMPT" 9223372036854775807 || { echo 'signed 64-bit maximum was rejected' >&2; exit 1; }
[[ "$(<"$ATTEMPT")" == 9223372036854775807 ]] || { echo 'maximum timestamp changed during write' >&2; exit 1; }
weather_attempt_recent "$ATTEMPT" 9223372036854775807 || { echo 'maximum timestamp was not handled safely' >&2; exit 1; }
if weather_mark_attempt "$ATTEMPT" 9223372036854775808; then
    echo 'timestamp above signed 64-bit maximum was accepted' >&2; exit 1
fi
if weather_attempt_recent "$ATTEMPT" 9223372036854775808; then
    echo 'now above signed 64-bit maximum was accepted' >&2; exit 1
fi

# Future markers, malformed content, and multi-token values never enter arithmetic.
printf '%s\n' 9 > "$ATTEMPT"
if weather_attempt_recent "$ATTEMPT" 8; then
    echo 'future retry marker was accepted' >&2; exit 1
fi
printf '%s\n' '08x' > "$ATTEMPT"
if weather_attempt_recent "$ATTEMPT" 10; then
    echo 'malformed retry marker was accepted' >&2; exit 1
fi

PWN="$TMP/timestamp-command-ran"
export WEATHER_TIMESTAMP_PWN="$PWN"
if weather_mark_attempt "$ATTEMPT" '0[$(touch "$WEATHER_TIMESTAMP_PWN")]'; then
    echo 'command-substitution timestamp was accepted' >&2; exit 1
fi
printf '%s\n' '0[$(touch "$WEATHER_TIMESTAMP_PWN")]' > "$ATTEMPT"
if weather_attempt_recent "$ATTEMPT" 10; then
    echo 'command-substitution retry marker was accepted' >&2; exit 1
fi
[[ ! -e "$PWN" ]] || { echo 'untrusted timestamp executed command substitution' >&2; exit 1; }

# Zero is a valid epoch and the future-time guard still applies.
weather_mark_attempt "$ATTEMPT" 00000 || { echo 'zero timestamp write failed' >&2; exit 1; }
[[ "$(<"$ATTEMPT")" == 0 ]] || { echo 'zero timestamp was not canonicalized' >&2; exit 1; }
weather_attempt_recent "$ATTEMPT" 0 || { echo 'zero timestamp was not accepted at epoch zero' >&2; exit 1; }

printf 'Weather attempt timestamp validation: decimal normalization, signed 64-bit bounds, and future-marker rejection: OK\n'
