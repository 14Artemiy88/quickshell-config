#!/bin/bash
set -euo pipefail

MOPIDY_RPC_URL="${MOPIDY_RPC_URL:-http://localhost:6680/mopidy/rpc}"
SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_DIR="${SCRIPT_PATH%/*}"
[[ "$SCRIPT_DIR" != "$SCRIPT_PATH" ]] || SCRIPT_DIR=.
source "$SCRIPT_DIR/pulse_mixer.sh"

state_dir="${QS_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/quickshell-widgets}"
restore_volume=""
if [[ -r "$state_dir/mopidy-volume-restore" ]]; then
    IFS= read -r restore_volume < "$state_dir/mopidy-volume-restore" || true
fi
restore_volume_json=null
if [[ "$restore_volume" =~ ^[0-9]+$ ]] && (( restore_volume >= 1 && restore_volume <= 100 )); then
    restore_volume_json="$restore_volume"
fi

emit_offline() {
    printf '{"mixer":{"ok":false,"volume":null,"mute":null,"restore_volume":%s},"playback":{"ok":false,"random":false,"repeat":false,"single":false}}\n' "$restore_volume_json"
}

case "${1:-state}" in
    state) ;;
    *) echo "Usage: $0 state" >&2; exit 2 ;;
esac

# Poll mixer and tracklist playback preferences in one JSON-RPC batch. These
# values are read-only and can share a request; actions still use their
# dedicated scripts so command semantics and acknowledgements stay unchanged.
response=$(curl -sS --connect-timeout 1 --max-time 3 \
    -H 'Content-Type: application/json' \
    -d '[
        {"jsonrpc":"2.0","id":1,"method":"core.mixer.get_volume"},
        {"jsonrpc":"2.0","id":2,"method":"core.mixer.get_mute"},
        {"jsonrpc":"2.0","id":3,"method":"core.tracklist.get_random"},
        {"jsonrpc":"2.0","id":4,"method":"core.tracklist.get_repeat"},
        {"jsonrpc":"2.0","id":5,"method":"core.tracklist.get_single"}
    ]' \
    "$MOPIDY_RPC_URL" 2>/dev/null) || {
    emit_offline
    exit 0
}

pulse_mute="$(mopidy_pulse_get_mute 2>/dev/null || true)"
jq -c --argjson restore_volume "$restore_volume_json" --arg pulse_mute "$pulse_mute" '
    def result($id):
        ([.[]? | select(.id == $id)][0] // {}) as $reply
        | if $reply.error? != null then null
          elif ($reply | has("result")) then $reply.result
          else null end;
    def bool_result($id):
        result($id) as $value
        | if ($value | type) == "boolean" then $value else null end;
    def effective_mute($id):
        bool_result($id) as $native
        | if $native == true or $pulse_mute == "true" then true
          elif $pulse_mute == "false" then false
          else $native end;

    (result(1)) as $raw_volume
    | (if ($raw_volume | type) == "number" and $raw_volume >= 0 and $raw_volume <= 100 and ($raw_volume | floor) == $raw_volume then $raw_volume else null end) as $volume
    | effective_mute(2) as $mute
    | bool_result(3) as $random
    | bool_result(4) as $repeat
    | bool_result(5) as $single
    | {
        mixer: {
            ok: ($volume != null or $mute != null),
            volume: $volume,
            mute: $mute,
            pulse_mute_available: ($pulse_mute == "true" or $pulse_mute == "false"),
            restore_volume: $restore_volume
        },
        playback: {
            ok: ($random != null and $repeat != null and $single != null),
            random: ($random // false),
            repeat: ($repeat // false),
            single: ($single // false)
        }
    }
' <<< "$response" 2>/dev/null || emit_offline
