#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
mkdir -p "$TMP_DIR/bin" "$TMP_DIR/runtime" "$TMP_DIR/config" "$TMP_DIR/data" "$TMP_DIR/state" "$TMP_DIR/cache"
export AWK_CALL_LOG="$TMP_DIR/awk-calls.log"
export PATH="$TMP_DIR/bin:$PATH"
export XDG_RUNTIME_DIR="$TMP_DIR/runtime"
export XDG_CONFIG_HOME="$TMP_DIR/config"
export XDG_DATA_HOME="$TMP_DIR/data"
export XDG_STATE_HOME="$TMP_DIR/state"
export XDG_CACHE_HOME="$TMP_DIR/cache"
export MPRIS_TITLE=$'A "quoted"\nsecond title line \\ path — 東京 🎵'
export MPRIS_ARTIST=$'Artist "Name"\nsecond artist line \\ Mix'
export MPRIS_POSITION=1000000
export MPRIS_LENGTH=60000000
export MPRIS_TIMELEFT='00:59'
export MPRIS_IMAGE=''
export MPRIS_URL='https://www.youtube.com/watch?v=test'

cat > "$TMP_DIR/bin/playerctl" <<'STUB'
#!/bin/bash
if [[ "${1:-}" == "-l" ]]; then
    printf 'spotify\n'
    exit 0
fi
if [[ "${1:-}" == "-p" && "${3:-}" == "metadata" ]]; then
    printf '%s\x1f%s\x1f%s\x1f%s\x1f%s\x1f%s\x1f%s\x1f%s\n' \
        'Playing' "$MPRIS_TITLE" "$MPRIS_ARTIST" "$MPRIS_POSITION" \
        "$MPRIS_LENGTH" "$MPRIS_TIMELEFT" "$MPRIS_IMAGE" "$MPRIS_URL"
    exit 0
fi
exit 1
STUB
chmod +x "$TMP_DIR/bin/playerctl"

# A valid MPRIS response must not spawn awk just to check that duration > 0.
cat > "$TMP_DIR/bin/awk" <<'STUB'
#!/bin/bash
printf '%s\n' "$*" >> "$AWK_CALL_LOG"
exit 99
STUB
chmod +x "$TMP_DIR/bin/awk"

output="$(bash -c 'source "$1"; source "$2"; get_mpris_player_metadata spotify' \
    _ "$ROOT/scripts/player.d/common.sh" "$ROOT/scripts/player.d/backend_mpris.sh")"

[[ ! -s "$AWK_CALL_LOG" ]] || { echo 'MPRIS duration check unexpectedly spawned awk' >&2; cat "$AWK_CALL_LOG" >&2; exit 1; }
jq -e --arg title "$MPRIS_TITLE" --arg artist "$MPRIS_ARTIST" \
    '.first_line == $title and .second_line == $artist and .player == "spotify" and .text == $artist and .duration == "60000000"' \
    <<< "$output" >/dev/null || {
    printf 'MPRIS metadata string changed during JSON serialization\nExpected title: %s\nJSON: %s\n' "$MPRIS_TITLE" "$output" >&2
    exit 1
}

# Regression guard: MPRIS keeps raw metadata intact; the shared Player serializer escapes JSON once.
if grep -Fq 'title=${title//\\\\/|}' "$ROOT/scripts/player.d/backend_mpris.sh" || \
   grep -Fq 'title=${title//\\"/\\\\\\"}' "$ROOT/scripts/player.d/backend_mpris.sh"; then
    echo 'MPRIS title is still manually escaped before the shared JSON serializer' >&2
    exit 1
fi
if grep -Fq '␞' "$ROOT/scripts/player.d/backend_mpris.sh"; then
    echo 'MPRIS field separator is still multi-byte Unicode' >&2
    exit 1
fi
if grep -Fq 'IFS="$s" read -r status title artist' "$ROOT/scripts/player.d/backend_mpris.sh"; then
    echo 'MPRIS metadata still uses line-limited read parsing' >&2
    exit 1
fi
printf 'MPRIS metadata string preservation: OK\n'
