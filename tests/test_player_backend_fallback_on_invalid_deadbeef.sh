#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
mkdir -p "$TMP_DIR/bin" "$TMP_DIR/runtime" "$TMP_DIR/config" "$TMP_DIR/data" "$TMP_DIR/state" "$TMP_DIR/cache" "$TMP_DIR/home"
export PATH="$TMP_DIR/bin:$PATH"
export HOME="$TMP_DIR/home"
export XDG_RUNTIME_DIR="$TMP_DIR/runtime"
export XDG_CONFIG_HOME="$TMP_DIR/config"
export XDG_DATA_HOME="$TMP_DIR/data"
export XDG_STATE_HOME="$TMP_DIR/state"
export XDG_CACHE_HOME="$TMP_DIR/cache"
export PLAYERCTL_CALL_LOG="$TMP_DIR/playerctl.log"

# A DeaDBeeF process exists, but its CLI temporarily returns a malformed
# metadata record. The player dispatcher must skip it and try the next backend.
cat > "$TMP_DIR/bin/pgrep" <<'STUB'
#!/bin/bash
[[ "${1:-}" == "-x" && "${2:-}" == 'deadbeef(-main)?' ]]
STUB
cat > "$TMP_DIR/bin/deadbeef" <<'STUB'
#!/bin/bash
if [[ "${1:-}" == "--nowplaying" && "${2:-}" == "%t" ]]; then
    printf 'Stale DeaDBeeF title\n'
    exit 0
fi
if [[ "${1:-}" == "--nowplaying-tf" ]]; then
    printf 'starting deadbeef...\n'
    printf '0|Incomplete DeaDBeeF response\n'
    exit 0
fi
exit 1
STUB
cat > "$TMP_DIR/bin/playerctl" <<'STUB'
#!/bin/bash
printf '%s\n' "$*" >> "$PLAYERCTL_CALL_LOG"
if [[ "${1:-}" == "-l" ]]; then
    printf 'spotify\n'
    exit 0
fi
if [[ "${1:-}" == "-p" && "${2:-}" == "spotify" && "${3:-}" == "metadata" && "${4:-}" == "-f" ]]; then
    printf 'Playing\x1fSpotify Track\x1fSpotify Artist\x1f1000000\x1f60000000\x1f00:59\x1f\x1fhttps://open.spotify.com/track/test\n'
    exit 0
fi
exit 1
STUB
chmod +x "$TMP_DIR/bin/pgrep" "$TMP_DIR/bin/deadbeef" "$TMP_DIR/bin/playerctl"

output="$("$ROOT/scripts/player" --priority deadbeef spotify)"
jq -e '.player == "spotify" and .first_line == "Spotify Track" and .second_line == "Spotify Artist"' <<< "$output" >/dev/null || {
    printf 'Invalid DeaDBeeF metadata prevented fallback to Spotify. JSON: %s\n' "$output" >&2
    exit 1
}
grep -Fxq -- '-l' "$PLAYERCTL_CALL_LOG" || {
    echo 'Player dispatcher did not try MPRIS after invalid DeaDBeeF response' >&2
    exit 1
}
printf 'Player fallback when DeaDBeeF metadata is invalid: OK\n'
