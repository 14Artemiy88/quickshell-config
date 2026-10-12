#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
MOCK_DIR="$(mktemp -d)"
trap 'rm -rf "$MOCK_DIR"' EXIT
STATE_FILE="$MOCK_DIR/state"
POSITION_FILE="$MOCK_DIR/position"
TLID_PLAY_FILE="$MOCK_DIR/tlid-play-seen"
CALLS_FILE="$MOCK_DIR/calls"
mkdir -p "$MOCK_DIR/user-state"
printf 'paused\n' > "$STATE_FILE"
printf '42000\n' > "$POSITION_FILE"
export QS_STATE_DIR="$MOCK_DIR/user-state"

source "$ROOT/scripts/mopidy/player_backend.sh"

# This mock is file-backed because mopidy_rpc is called in command substitutions,
# which execute shell functions in subshells. Simulate a provider that rejects
# resume but accepts explicit play of the current tlid.
mopidy_rpc() {
  local method="$1" params="${2:-}" position
  printf '%s %s\n' "$method" "$params" >> "$CALLS_FILE"
  case "$method" in
    core.playback.get_state)
      printf '{"result":"%s"}\n' "$(cat "$STATE_FILE")"
      ;;
    core.playback.get_current_tl_track)
      printf '{"result":{"tlid":37,"track":{"uri":"file:///track.ogg","length":90000}}}\n'
      ;;
    core.playback.get_time_position)
      printf '{"result":%s}\n' "$(cat "$POSITION_FILE")"
      ;;
    core.playback.resume)
      printf '{"error":{"message":"resume unsupported"}}\n'
      ;;
    core.playback.stop)
      printf 'stopped\n' > "$STATE_FILE"
      printf '{"result":null}\n'
      ;;
    core.playback.play)
      [[ "$params" == *'"tlid":37'* ]] || { echo "play missing tlid: $params" >&2; return 1; }
      : > "$TLID_PLAY_FILE"
      printf 'playing\n' > "$STATE_FILE"
      printf '1000\n' > "$POSITION_FILE"
      printf '{"result":null}\n'
      ;;
    core.playback.seek)
      position=$(jq -r '.time_position' <<< "$params")
      printf '%s\n' "$position" > "$POSITION_FILE"
      printf '{"result":true}\n'
      ;;
    *) printf '{"result":null}\n' ;;
  esac
}

mopidy_pause_toggle
[[ "$(cat "$STATE_FILE")" == playing ]]
[[ "$(cat "$POSITION_FILE")" == 42000 ]]
[[ -f "$TLID_PLAY_FILE" ]]
printf 'mopidy resume mock: OK (explicit tlid play + position restore)\n'
