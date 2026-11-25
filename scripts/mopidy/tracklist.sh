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
            {"jsonrpc":"2.0","id":3,"method":"core.playback.get_time_position"},
            {"jsonrpc":"2.0","id":4,"method":"core.tracklist.get_version"}
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
        | ([$batch[] | select(.id == 4) | .result?][0] // null) as $raw_version
        | {
            ok: true,
            tracklist_version: (
                if ($raw_version | type) == "number" and $raw_version >= 0 and ($raw_version | floor) == $raw_version then $raw_version
                elif ($raw_version | type) == "string" and ($raw_version | test("^[0-9]+$")) then ($raw_version | tonumber)
                else null end
            ),
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

get_position_state() {
    local response
    response=$(curl -sS --connect-timeout 1 --max-time 2 \
        -H 'Content-Type: application/json' \
        -d '[
            {"jsonrpc":"2.0","id":1,"method":"core.tracklist.get_version"},
            {"jsonrpc":"2.0","id":2,"method":"core.playback.get_current_tl_track"},
            {"jsonrpc":"2.0","id":3,"method":"core.playback.get_time_position"}
        ]' \
        "$MOPIDY_RPC_URL" 2>/dev/null) || {
        printf '{"ok":false,"current_tlid":null,"position_ms":0,"tracklist_version":null,"error":"offline"}\n'
        return 0
    }

    # The one-second UI countdown only needs the current track, playback
    # position and tracklist version. Avoid serializing the whole queue on each
    # tick; the caller fetches it only when the version or current tlid changes.
    jq -c '
        def nonnegative_int_or_zero:
            if type == "number" then
                if . >= 0 and floor == . then . else 0 end
            elif type == "string" and test("^[0-9]+$") then tonumber
            else 0 end;

        . as $batch
        | ([$batch[] | select(.id == 1) | .result?][0] // null) as $raw_version
        | ([$batch[] | select(.id == 2) | .result.tlid?][0] // null) as $raw_tlid
        | ([$batch[] | select(.id == 3) | .result?][0] // 0 | nonnegative_int_or_zero) as $position_ms
        | {
            ok: (
                ((($raw_version | type) == "number" and $raw_version >= 0 and ($raw_version | floor) == $raw_version) or
                 (($raw_version | type) == "string" and ($raw_version | test("^[0-9]+$")))) and
                ([$batch[] | select(.id == 2)] | length) == 1 and
                ([$batch[] | select(.id == 3)] | length) == 1 and
                ([$batch[] | select((.id == 1 or .id == 2 or .id == 3) and .error? != null)] | length) == 0
            ),
            tracklist_version: (
                if ($raw_version | type) == "number" and $raw_version >= 0 and ($raw_version | floor) == $raw_version then $raw_version
                elif ($raw_version | type) == "string" and ($raw_version | test("^[0-9]+$")) then ($raw_version | tonumber)
                else null end
            ),
            current_tlid: (
                if $raw_tlid == null then null
                elif ($raw_tlid | type) == "number" then $raw_tlid
                elif ($raw_tlid | type) == "string" and ($raw_tlid | test("^[0-9]+$")) then ($raw_tlid | tonumber)
                else null end
            ),
            position_ms: $position_ms
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
    local tlid="${1:-}" position="${2:-}" expected_version="${3:-}"
    if [[ ! "$tlid" =~ ^[0-9]+$ || ! "$position" =~ ^[0-9]+$ || ! "$expected_version" =~ ^[0-9]+$ ]]; then
        printf '{"ok":false,"error":"invalid_argument"}\n'
        return 0
    fi

    local version_response current_version index_response index length_response length
    local move_response verify_response actual_tlid

    version_response="$(rpc 'core.tracklist.get_version')" || {
        printf '{"ok":false,"error":"offline"}\n'
        return 0
    }
    current_version="$(jq -r '.result // empty' <<< "$version_response" 2>/dev/null || true)"
    if [[ ! "$current_version" =~ ^[0-9]+$ ]] || jq -e '.error != null' >/dev/null 2>&1 <<< "$version_response"; then
        printf '{"ok":false,"error":"queue_version_unavailable"}\n'
        return 0
    fi
    if [[ "$current_version" != "$expected_version" ]]; then
        printf '{"ok":false,"error":"queue_changed"}\n'
        return 0
    fi

    length_response="$(rpc 'core.tracklist.get_length')" || {
        printf '{"ok":false,"error":"offline"}\n'
        return 0
    }
    length="$(jq -r '.result // empty' <<< "$length_response" 2>/dev/null || true)"
    if [[ ! "$length" =~ ^[0-9]+$ ]] || jq -e '.error != null' >/dev/null 2>&1 <<< "$length_response"; then
        printf '{"ok":false,"error":"queue_unavailable"}\n'
        return 0
    fi
    if (( position >= length )); then
        printf '{"ok":false,"error":"invalid_position"}\n'
        return 0
    fi

    index_response="$(rpc 'core.tracklist.index' "$(jq -cn --argjson tlid "$tlid" '{tlid:$tlid}')")" || {
        printf '{"ok":false,"error":"offline"}\n'
        return 0
    }
    if jq -e '.error != null' >/dev/null 2>&1 <<< "$index_response"; then
        printf '{"ok":false,"error":"track_not_found"}\n'
        return 0
    fi
    index="$(jq -r '.result // empty' <<< "$index_response" 2>/dev/null || true)"
    if [[ ! "$index" =~ ^[0-9]+$ ]] || (( index >= length )); then
        printf '{"ok":false,"error":"track_not_found"}\n'
        return 0
    fi
    if (( index == position )); then
        jq -cn --argjson tlid "$tlid" --argjson position "$position" '{ok:true,unchanged:true,tlid:$tlid,position:$position}'
        return 0
    fi

    # Re-check the version immediately before mutating the tracklist. Mopidy's
    # move API removes [start:end] first and inserts at to_position in the
    # resulting list, so the final UI index is passed unchanged.
    version_response="$(rpc 'core.tracklist.get_version')" || {
        printf '{"ok":false,"error":"offline"}\n'
        return 0
    }
    current_version="$(jq -r '.result // empty' <<< "$version_response" 2>/dev/null || true)"
    if [[ ! "$current_version" =~ ^[0-9]+$ ]] || jq -e '.error != null' >/dev/null 2>&1 <<< "$version_response"; then
        printf '{"ok":false,"error":"queue_version_unavailable"}\n'
        return 0
    fi
    if [[ "$current_version" != "$expected_version" ]]; then
        printf '{"ok":false,"error":"queue_changed"}\n'
        return 0
    fi

    move_response="$(rpc 'core.tracklist.move' "$(jq -cn --argjson start "$index" --argjson end "$((index + 1))" --argjson to_position "$position" '{start:$start,end:$end,to_position:$to_position}')")" || {
        printf '{"ok":false,"error":"offline"}\n'
        return 0
    }
    if jq -e '.error != null' >/dev/null 2>&1 <<< "$move_response"; then
        printf '{"ok":false,"error":"move_rejected"}\n'
        return 0
    fi

    # The JSON-RPC method returns null on success. Confirm the authoritative
    # order before the UI is allowed to treat the move as complete.
    verify_response="$(rpc 'core.tracklist.get_tl_tracks')" || {
        printf '{"ok":false,"error":"move_unconfirmed"}\n'
        return 0
    }
    if jq -e '.error != null or (.result | type != "array")' >/dev/null 2>&1 <<< "$verify_response"; then
        printf '{"ok":false,"error":"move_unconfirmed"}\n'
        return 0
    fi
    actual_tlid="$(jq -r --argjson position "$position" '.result[$position].tlid // empty' <<< "$verify_response" 2>/dev/null || true)"
    if [[ "$actual_tlid" != "$tlid" ]]; then
        printf '{"ok":false,"error":"move_unconfirmed"}\n'
        return 0
    fi
    jq -cn --argjson tlid "$tlid" --argjson from "$index" --argjson to "$position" '{ok:true,tlid:$tlid,from:$from,to:$to}'
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
    position)
        get_position_state
        ;;
    play)
        play_track "${2:-}"
        ;;
    remove)
        remove_track "${2:-}"
        ;;
    move)
        move_track "${2:-}" "${3:-}" "${4:-}"
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
        printf 'usage: %s {get|position|play|remove|move|clear|stop|remove_album} [args...]\n' "$0" >&2
        exit 2
        ;;
esac
