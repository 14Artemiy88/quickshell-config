#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
mkdir -p "$TMP_DIR/bin" "$TMP_DIR/runtime" "$TMP_DIR/config" "$TMP_DIR/data" "$TMP_DIR/state" "$TMP_DIR/cache" "$TMP_DIR/home" "$TMP_DIR/media"
export PATH="$TMP_DIR/bin:$PATH"
export HOME="$TMP_DIR/home"
export XDG_RUNTIME_DIR="$TMP_DIR/runtime"
export XDG_CONFIG_HOME="$TMP_DIR/config"
export XDG_DATA_HOME="$TMP_DIR/data"
export XDG_STATE_HOME="$TMP_DIR/state"
export XDG_CACHE_HOME="$TMP_DIR/cache"
MEDIA_FILE="$TMP_DIR/media/track.mp3"
printf 'fake media' > "$MEDIA_FILE"
printf 'fake cover' > "$TMP_DIR/media/cover.png"
export DB_PATH="$MEDIA_FILE"
export EXPECTED_COVER="$TMP_DIR/media/cover.png"

cat > "$TMP_DIR/bin/pgrep" <<'STUB'
#!/bin/bash
[[ "${1:-}" == "-x" && "${2:-}" == "${EXPECTED_DEADBEEF_COMM:-deadbeef-main}" ]]
STUB
cat > "$TMP_DIR/bin/deadbeef" <<'STUB'
#!/bin/bash
if [[ "${1:-}" == "--nowplaying" && "${2:-}" == "%t" ]]; then
    printf 'Regression Test Track\n'
    exit 0
fi
if [[ "${1:-}" == "--nowplaying-tf" ]]; then
    [[ "${2:-}" == '$if(%ispaused%,1,0)|'* ]] || exit 41
    printf 'starting deadbeef...\n'
    printf '%s|Test Artist|2025|Test Album|300|12.5|-00:42|%s\n' "${EXPECTED_DB_STATUS:-0}" "$DB_PATH"
    exit 0
fi
exit 1
STUB
chmod +x "$TMP_DIR/bin/pgrep" "$TMP_DIR/bin/deadbeef"

run_backend_case() {
    local process_comm="$1" playback_status="$2" expected_icon output
    EXPECTED_DEADBEEF_COMM="$process_comm" export EXPECTED_DEADBEEF_COMM
    EXPECTED_DB_STATUS="$playback_status" export EXPECTED_DB_STATUS
    if [[ "$playback_status" == "1" ]]; then
        expected_icon=''
    else
        expected_icon=''
    fi
    output="$(bash -c 'source "$1"; source "$2"; get_deadbeef_player_metadata' \
        _ "$ROOT/scripts/player.d/common.sh" "$ROOT/scripts/player.d/backend_deadbeef.sh")"
    jq -e --arg cover "$EXPECTED_COVER" --arg icon "$expected_icon" \
      '.player == "deadbeef" and .third_line == "Regression Test Track" and .first_line == "Test Artist" and .second_line == "2025 - Test Album" and .image == $cover and .duration == "300000" and .position == "4" and .status == $icon' \
      <<< "$output" >/dev/null || {
        printf 'DeaDBeeF backend failed for process name %s and status %s.\nJSON: %s\n' "$process_comm" "$playback_status" "$output" >&2
        exit 1
      }
}

run_backend_case deadbeef-main 0
run_backend_case deadbeef-main 1
run_backend_case deadbeef 0
run_backend_case deadbeef 1
printf 'DeaDBeeF backend playback regression (playing/paused and both process names): OK\n'
