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
export DEADBEEF_CALL_LOG="$TMP_DIR/deadbeef-calls.log"
export PGREP_CALL_LOG="$TMP_DIR/pgrep-calls.log"

cat > "$TMP_DIR/bin/pgrep" <<'STUB'
#!/bin/bash
printf '%s\n' "$*" >> "$PGREP_CALL_LOG"
[[ "${1:-}" == "-x" && "${2:-}" == 'deadbeef(-main)?' ]] || exit 2
[[ "${EXPECTED_DEADBEEF_COMM:-deadbeef-main}" == deadbeef-main || "${EXPECTED_DEADBEEF_COMM:-deadbeef-main}" == deadbeef ]]
STUB
cat > "$TMP_DIR/bin/deadbeef" <<'STUB'
#!/bin/bash
printf '%s\n' "$*" >> "$DEADBEEF_CALL_LOG"
if [[ "${1:-}" == "--nowplaying-tf" ]]; then
    [[ "${2:-}" == '$if(%ispaused%,1,0)|'*'%title%' ]] || exit 41
    printf 'starting deadbeef...\n'
    printf '%s|Test Artist|2025|Test Album|300|12.5|-00:42|%s|%s\n' \
        "${EXPECTED_DB_STATUS:-0}" "$DB_PATH" "${EXPECTED_DB_TITLE:-Regression Test Track}"
    exit 0
fi
exit 1
STUB
chmod +x "$TMP_DIR/bin/pgrep" "$TMP_DIR/bin/deadbeef"

run_backend_case() {
    local process_comm="$1" playback_status="$2" expected_icon output
    EXPECTED_DEADBEEF_COMM="$process_comm"; export EXPECTED_DEADBEEF_COMM
    EXPECTED_DB_STATUS="$playback_status"; export EXPECTED_DB_STATUS
    EXPECTED_DB_TITLE='Regression Test Track'; export EXPECTED_DB_TITLE
    : > "$DEADBEEF_CALL_LOG"
    : > "$PGREP_CALL_LOG"
    if [[ "$playback_status" == "1" ]]; then expected_icon=''; else expected_icon=''; fi
    output="$(bash -c 'source "$1"; source "$2"; get_deadbeef_player_metadata' \
        _ "$ROOT/scripts/player.d/common.sh" "$ROOT/scripts/player.d/backend_deadbeef.sh")"
    jq -e --arg cover "$EXPECTED_COVER" --arg icon "$expected_icon" \
      '.player == "deadbeef" and .third_line == "Regression Test Track" and .first_line == "Test Artist" and .second_line == "2025 - Test Album" and .image == $cover and .duration == "300000" and .position == "4" and .status == $icon' \
      <<< "$output" >/dev/null || {
        printf 'DeaDBeeF backend failed for process name %s and status %s.\nJSON: %s\n' "$process_comm" "$playback_status" "$output" >&2
        exit 1
      }
    mapfile -t calls < "$DEADBEEF_CALL_LOG"
    [[ ${#calls[@]} -eq 1 && "${calls[0]}" == --nowplaying-tf* ]] || {
        printf 'Expected exactly one --nowplaying-tf call; got %s\n' "${calls[*]}" >&2
        exit 1
    }
    mapfile -t pgrep_calls < "$PGREP_CALL_LOG"
    [[ ${#pgrep_calls[@]} -eq 1 && "${pgrep_calls[0]}" == '-x deadbeef(-main)?' ]] || {
        printf 'Expected one combined process-name check; got %s\n' "${pgrep_calls[*]}" >&2
        exit 1
    }
}

run_backend_case deadbeef-main 0
run_backend_case deadbeef-main 1
run_backend_case deadbeef 0
run_backend_case deadbeef 1

# If neither accepted process name is present, one combined pgrep check
# must reject the backend without starting the DeaDBeeF CLI.
: > "$DEADBEEF_CALL_LOG"
: > "$PGREP_CALL_LOG"
EXPECTED_DEADBEEF_COMM=absent; export EXPECTED_DEADBEEF_COMM
output="$(bash -c 'source "$1"; source "$2"; get_deadbeef_player_metadata' \
    _ "$ROOT/scripts/player.d/common.sh" "$ROOT/scripts/player.d/backend_deadbeef.sh")" || true
[[ -z "$output" ]] || { printf 'Absent DeaDBeeF emitted a payload: %s\n' "$output" >&2; exit 1; }
[[ ! -s "$DEADBEEF_CALL_LOG" ]] || { echo 'DeaDBeeF CLI started with no matching process' >&2; exit 1; }
mapfile -t pgrep_calls < "$PGREP_CALL_LOG"
[[ ${#pgrep_calls[@]} -eq 1 && "${pgrep_calls[0]}" == '-x deadbeef(-main)?' ]] || {
    printf 'Absent-process path should use one combined pgrep; got %s\n' "${pgrep_calls[*]}" >&2
    exit 1
}
EXPECTED_DEADBEEF_COMM=deadbeef-main; export EXPECTED_DEADBEEF_COMM

# Pipes and embedded newlines in the final title should be preserved intact.
: > "$DEADBEEF_CALL_LOG"
EXPECTED_DEADBEEF_COMM=deadbeef-main; export EXPECTED_DEADBEEF_COMM
EXPECTED_DB_STATUS=0; export EXPECTED_DB_STATUS
EXPECTED_DB_TITLE=$'Regression |\nPipe Track'; export EXPECTED_DB_TITLE
output="$(bash -c 'source "$1"; source "$2"; get_deadbeef_player_metadata' \
    _ "$ROOT/scripts/player.d/common.sh" "$ROOT/scripts/player.d/backend_deadbeef.sh")"
jq -e '.third_line == "Regression |\nPipe Track" and .first_line == "Test Artist" and .duration == "300000"' \
    <<< "$output" >/dev/null || { printf 'Pipe in DeaDBeeF title was not preserved: %s\n' "$output" >&2; exit 1; }
mapfile -t calls < "$DEADBEEF_CALL_LOG"
[[ ${#calls[@]} -eq 1 ]] || { printf 'Expected one call when title contains a pipe\n' >&2; exit 1; }

# An empty/stopped response should emit no synthetic payload, also with one call.
: > "$DEADBEEF_CALL_LOG"
EXPECTED_DB_TITLE='nothing'; export EXPECTED_DB_TITLE
if output="$(bash -c 'source "$1"; source "$2"; get_deadbeef_player_metadata' \
    _ "$ROOT/scripts/player.d/common.sh" "$ROOT/scripts/player.d/backend_deadbeef.sh")"; then
    :
fi
[[ -z "$output" ]] || { printf 'Stopped DeaDBeeF emitted a payload: %s\n' "$output" >&2; exit 1; }
mapfile -t calls < "$DEADBEEF_CALL_LOG"
[[ ${#calls[@]} -eq 1 ]] || { printf 'Expected one call for stopped DeaDBeeF response\n' >&2; exit 1; }
printf 'DeaDBeeF backend: combined process-name probe, single CLI call, playing/paused, both process names, pipe/newline titles and stopped state OK\n'
