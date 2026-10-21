#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
mkdir -p "$TMP_DIR"/{home,config,data,state,cache,runtime}
export HOME="$TMP_DIR/home" XDG_CONFIG_HOME="$TMP_DIR/config" XDG_DATA_HOME="$TMP_DIR/data"
export XDG_STATE_HOME="$TMP_DIR/state" XDG_CACHE_HOME="$TMP_DIR/cache" XDG_RUNTIME_DIR="$TMP_DIR/runtime"
export QS_PROJECT_DIR="$ROOT"
source "$ROOT/scripts/player.d/common.sh"
fail() { echo "Mopidy inline time format: FAIL: $*" >&2; exit 1; }

if grep -Fq 'time_left=$(timeFormat' "$ROOT/scripts/mopidy/player_backend.sh"; then
    fail 'Mopidy still invokes timeFormat through command substitution'
fi
grep -Fq 'timeFormat_into time_left' "$ROOT/scripts/mopidy/player_backend.sh" || fail 'Mopidy direct assignment call is missing'

for milliseconds in -12345 -1000 0 999 12345 2400000 3600000 86400000; do
    expected="$(timeFormat "$milliseconds")"
    expected="${expected%$'\n'}"
    timeFormat_into actual "$milliseconds" || fail "timeFormat_into failed for $milliseconds"
    [[ "$actual" == "$expected" ]] || fail "format mismatch for $milliseconds: '$actual' != '$expected'"
done
printf 'Mopidy inline time format: OK\n'
