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
export MPV_RUNNING=1

cat > "$TMP_DIR/bin/pgrep" <<'STUB'
#!/bin/bash
[[ "${1:-}" == "-x" && "${2:-}" == "mpv" && "${MPV_RUNNING:-0}" == "1" ]]
STUB
cat > "$TMP_DIR/bin/socat" <<'STUB'
#!/bin/bash
printf '%s' "${MPV_RESPONSE:-}"
STUB
cat > "$TMP_DIR/bin/playerctl" <<'STUB'
#!/bin/bash
if [[ "${1:-}" == "-l" ]]; then
    printf 'spotify\nplasma-browser-integration\n'
    exit 0
fi
if [[ "${1:-}" == "-p" && "${3:-}" == "metadata" && "${4:-}" == "-f" ]]; then
    case "$2" in
        spotify) printf '%s\n' "${MPRIS_SPOTIFY:-}" ;;
        plasma-browser-integration) printf '%s\n' "${MPRIS_BROWSER:-}" ;;
        *) exit 1 ;;
    esac
    exit 0
fi
exit 1
STUB
chmod +x "$TMP_DIR/bin/pgrep" "$TMP_DIR/bin/socat" "$TMP_DIR/bin/playerctl"

# mpv reports that the process and socket exist, but the title property is
# unavailable while transitioning. Its backend must decline and let Spotify
# provide the visible player state.
python3 - "$XDG_RUNTIME_DIR/mpvsocket" <<'PY'
import socket, sys
sock = socket.socket(socket.AF_UNIX)
sock.bind(sys.argv[1])
sock.close()
PY
export MPV_RESPONSE=$'{"request_id":1,"error":"property unavailable"}\n{"request_id":2,"data":12.5}\n{"request_id":3,"data":120}\n{"request_id":4,"data":"/tmp/not-a-real-video.mkv"}\n'
export MPRIS_SPOTIFY=$'Playing\x1fSpotify Track\x1fSpotify Artist\x1f1000000\x1f60000000\x1f00:59\x1f\x1fhttps://www.youtube.com/watch?v=test'
export MPRIS_BROWSER=$'Playing\x1fBrowser Track\x1fBrowser Artist\x1f2000000\x1f60000000\x1f00:58\x1f\x1fhttps://www.youtube.com/watch?v=browser'
output="$("$ROOT/scripts/player" --priority mpv spotify)"
jq -e '.player == "spotify" and .first_line == "Spotify Track"' <<< "$output" >/dev/null || {
    printf 'Invalid mpv IPC response blocked Spotify fallback. JSON: %s\n' "$output" >&2
    exit 1
}

# A stopped MPRIS instance can leave stale track metadata behind. It must not
# claim the PlayerWidget ahead of a healthy configured backend.
export MPRIS_SPOTIFY=$'Stopped\\x1fStale Spotify Track\\x1fSpotify Artist\\x1f1000000\\x1f60000000\\x1f00:59\\x1f\\x1fhttps://www.youtube.com/watch?v=test'
output="$("$ROOT/scripts/player" --priority spotify plasma-browser-integration)"
jq -e '.player == "plasma-browser-integration" and .first_line == "Browser Track"' <<< "$output" >/dev/null || {
    printf 'Stopped Spotify metadata blocked browser fallback. JSON: %s\n' "$output" >&2
    exit 1
}

# Non-numeric position is malformed data, not a usable progress response.
export MPRIS_SPOTIFY=$'Playing\x1fStale Spotify Track\x1fSpotify Artist\x1fnot-a-position\x1f60000000\x1f00:59\x1f\x1fhttps://www.youtube.com/watch?v=test'
output="$("$ROOT/scripts/player" --priority spotify plasma-browser-integration)"
jq -e '.player == "plasma-browser-integration" and .first_line == "Browser Track"' <<< "$output" >/dev/null || {
    printf 'Malformed MPRIS position blocked browser fallback. JSON: %s\n' "$output" >&2
    exit 1
}

# Empty titles are common while a service starts or switches items. Do not
# treat them as a playing track and suppress the next backend.
export MPRIS_SPOTIFY=$'Playing\x1f   \x1fSpotify Artist\x1f1000000\x1f60000000\x1f00:59\x1f\x1fhttps://www.youtube.com/watch?v=test'
output="$("$ROOT/scripts/player" --priority spotify plasma-browser-integration)"
jq -e '.player == "plasma-browser-integration" and .first_line == "Browser Track"' <<< "$output" >/dev/null || {
    printf 'Empty MPRIS title blocked browser fallback. JSON: %s\n' "$output" >&2
    exit 1
}



# mpv live streams may have a valid title/position but no known duration or
# file path. Keep the backend metadata without fabricating a zero countdown or
# a 0% progress measurement.
export MPV_RESPONSE=$'{"request_id":1,"data":"Live Stream Title"}\n{"request_id":2,"data":12.5}\n{"request_id":3,"data":null}\n{"request_id":4,"data":null}\n'
output="$($ROOT/scripts/player --priority mpv spotify)"
jq -e '.player == "mpv" and .first_line == "Live Stream Title" and .duration == "" and .timeleft == "" and .position == ""' <<< "$output" >/dev/null || {
    printf 'Valid live mpv metadata without duration was not preserved cleanly. JSON: %s\n' "$output" >&2
    exit 1
}

# Some mpv versions or streams report duration=0 instead of null when their
# length is unknown; handle that sentinel the same way.
export MPV_RESPONSE=$'{"request_id":1,"data":"Live Stream Title"}\n{"request_id":2,"data":12.5}\n{"request_id":3,"data":0}\n{"request_id":4,"data":null}\n'
output="$("$ROOT/scripts/player" --priority mpv spotify)"
jq -e '.player == "mpv" and .first_line == "Live Stream Title" and .duration == "" and .timeleft == "" and .position == ""' <<< "$output" >/dev/null || {
    printf 'Live mpv metadata with zero duration was not preserved cleanly. JSON: %s\n' "$output" >&2
    exit 1
}

printf 'Player backend fallback on invalid mpv/MPRIS metadata: OK\n'
