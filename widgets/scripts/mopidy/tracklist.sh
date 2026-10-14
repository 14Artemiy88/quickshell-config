#!/bin/bash
set -euo pipefail

MOPIDY_RPC_URL="${MOPIDY_RPC_URL:-http://localhost:6680/mopidy/rpc}"

rpc() {
    local method="$1"
    local params="{}"
    [[ -n "${2:-}" ]] && params="$2"

    curl -sS --connect-timeout 1 --max-time 2 \
        -H 'Content-Type: application/json' \
        -d "$(jq -cn --argjson params "$params" --arg method "$method" '{jsonrpc:"2.0",id:1,method:$method,params:$params}')" \
        "$MOPIDY_RPC_URL" 2>/dev/null
}

get_queue() {
    local response
    response=$(curl -sS --connect-timeout 1 --max-time 2 \
        -H 'Content-Type: application/json' \
        -d '[
            {"jsonrpc":"2.0","id":1,"method":"core.tracklist.get_tl_tracks"},
            {"jsonrpc":"2.0","id":2,"method":"core.playback.get_current_tl_track"},
            {"jsonrpc":"2.0","id":3,"method":"core.playback.get_time_position"}
        ]' \
        "$MOPIDY_RPC_URL" 2>/dev/null) || {
        printf '{"ok":false,"current_tlid":null,"tracks":[],"error":"offline"}\n'
        return 0
    }

    # The batch response already contains tracklist, current track and playback
    # position. Extract and normalize all three in one jq process instead of
    # parsing it twice for scalar fields and once again for the final payload.
    jq -c '
        def nonnegative_int_or_zero:
            if type == "number" then
                if . >= 0 and floor == . then . else 0 end
            elif type == "string" and test("^[0-9]+$") then tonumber
            else 0 end;

        . as $batch
        | ([$batch[] | select(.id == 2) | .result.tlid?][0] // null) as $current_tlid
        | ([$batch[] | select(.id == 3) | .result?][0] // 0 | nonnegative_int_or_zero) as $position_ms
        | {
            ok: true,
            current_tlid: (
                if $current_tlid == null then null
                elif ($current_tlid | type) == "number" then $current_tlid
                elif ($current_tlid | type) == "string" and ($current_tlid | test("^[0-9]+$")) then ($current_tlid | tonumber)
                else null end
            ),
            position_ms: $position_ms,
            tracks: ([$batch[] | select(.id == 1) | .result[]? | {
                tlid: .tlid,
                name: (.track.name // "Без названия"),
                artist: ([.track.artists[]?.name] | join(", ")),
                album: (.track.album.name // ""),
                albumDate: (.track.album.date // ""),
                duration: (.track.length // 0),
                uri: (.track.uri // "")
            }])
        }
    ' <<< "$response"
}

play_track() {
    local tlid="$1"
    [[ "$tlid" =~ ^[0-9]+$ ]] || exit 2
    rpc 'core.playback.play' "$(jq -cn --argjson tlid "$tlid" '{tlid:$tlid}')" >/dev/null
}

remove_track() {
    local tlid="$1"
    [[ "$tlid" =~ ^[0-9]+$ ]] || exit 2
    rpc 'core.tracklist.remove' "$(jq -cn --argjson tlid "$tlid" '{criteria:{tlid:[$tlid]}}')" >/dev/null
}

move_track() {
    local tlid="$1"
    local position="$2"
    [[ "$tlid" =~ ^[0-9]+$ ]] || exit 2
    [[ "$position" =~ ^[0-9]+$ ]] || exit 2

    local index_response index move_response
    index_response="$(rpc 'core.tracklist.index' "$(jq -cn --argjson tlid "$tlid" '{tlid:$tlid}')" || true)"
    index="$(jq -r '.result // empty' <<< "$index_response")"
    [[ "$index" =~ ^[0-9]+$ ]] || exit 1

    move_response="$(rpc 'core.tracklist.move' "$(jq -cn --argjson start "$index" --argjson end "$((index + 1))" --argjson to_position "$position" '{start:$start,end:$end,to_position:$to_position}')" || true)"
    if jq -e '.error != null' >/dev/null 2>&1 <<< "$move_response"; then
        exit 1
    fi
}

clear_queue() {
    rpc 'core.tracklist.clear' >/dev/null
}

stop_playback() {
    rpc 'core.playback.stop' >/dev/null
}

remove_album() {
    shift || true
    (( $# > 0 )) || exit 0

    local tlids_json
    local tlid
    for tlid in "$@"; do
        [[ "$tlid" =~ ^[0-9]+$ ]] || exit 2
    done

    tlids_json=$(printf '%s\n' "$@" | jq -Rsc 'split("\n") | map(select(length > 0) | tonumber)')
    rpc 'core.tracklist.remove' "$(jq -cn --argjson tlids "$tlids_json" '{criteria:{tlid:$tlids}}')" >/dev/null
}

case "${1:-get}" in
    get)
        get_queue
        ;;
    play)
        play_track "${2:-}"
        ;;
    remove)
        remove_track "${2:-}"
        ;;
    move)
        move_track "${2:-}" "${3:-}"
        ;;
    clear)
        clear_queue
        ;;
    stop)
        stop_playback
        ;;
    remove_album)
        remove_album "$@"
        ;;
    *)
        printf 'usage: %s {get|play|remove|move|clear|stop|remove_album} [args...]\n' "$0" >&2
        exit 2
        ;;
esac
