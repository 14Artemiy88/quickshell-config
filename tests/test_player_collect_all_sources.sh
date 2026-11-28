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

cat > "$TMP_DIR/bin/pgrep" <<'STUB'
#!/bin/bash
[[ "${1:-}" == "-x" && "${2:-}" == 'deadbeef(-main)?' ]]
STUB
cat > "$TMP_DIR/bin/deadbeef" <<'STUB'
#!/bin/bash
if [[ "${1:-}" == "--nowplaying-tf" ]]; then
    printf '0|DeaDBeeF Artist|2024|Local Album|180|30|-2:30|/tmp/local.ogg|Local Track\n'
    exit 0
fi
exit 1
STUB
cat > "$TMP_DIR/bin/playerctl" <<'STUB'
#!/bin/bash
if [[ "${1:-}" == "-l" ]]; then
    printf 'spotify\n'
    exit 0
fi
if [[ "${1:-}" == "-p" && "${2:-}" == "spotify" && "${3:-}" == "metadata" && "${4:-}" == "-f" ]]; then
    printf 'Paused\x1fSpotify Track\x1fSpotify Artist\x1f30000000\x1f240000000\x1f-03:30\x1f\x1fhttps://open.spotify.com/track/test\n'
    exit 0
fi
exit 1
STUB
chmod +x "$TMP_DIR/bin/pgrep" "$TMP_DIR/bin/deadbeef" "$TMP_DIR/bin/playerctl"

all_output="$("$ROOT/scripts/player" --all --priority deadbeef spotify)"
jq -e 'type == "array" and length == 2
  and .[0].player == "deadbeef" and .[0].third_line == "Local Track"
  and .[1].player == "spotify" and .[1].first_line == "Spotify Track"' <<< "$all_output" >/dev/null || {
    printf 'Dashboard all-source discovery did not return both valid backends. JSON: %s\n' "$all_output" >&2
    exit 1
}

normal_output="$("$ROOT/scripts/player" --priority deadbeef spotify)"
jq -e 'type == "object" and .player == "deadbeef" and .third_line == "Local Track"' <<< "$normal_output" >/dev/null || {
    printf 'Normal priority mode changed while adding all-source discovery. JSON: %s\n' "$normal_output" >&2
    exit 1
}
printf 'Player all-source discovery and unchanged priority mode: OK\n'
