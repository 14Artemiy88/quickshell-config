#!/bin/bash

MOPIDY_RPC_URL="${MOPIDY_RPC_URL:-http://localhost:6680/mopidy/rpc}"

mopidy_rpc() {
    local method="$1"
    local params="{}"
    [[ -n "${2:-}" ]] && params="$2"
    curl -sS --connect-timeout 1 --max-time 2 \
        -H 'Content-Type: application/json' \
        -d "$(jq -cn --argjson params "$params" --arg method "$method" '{jsonrpc:"2.0",id:1,method:$method,params:$params}')" \
        "$MOPIDY_RPC_URL" 2>/dev/null
}

mopidy_pause_toggle() {
    local state
    state=$(mopidy_rpc 'core.playback.get_state' | jq -r '.result // empty')
    case "$state" in
        playing) mopidy_rpc 'core.playback.pause' >/dev/null ;;
        paused) mopidy_rpc 'core.playback.resume' >/dev/null ;;
        stopped) mopidy_rpc 'core.playback.play' >/dev/null ;;
        *) return 1 ;;
    esac
}

mopidy_next() {
    mopidy_rpc 'core.playback.next' >/dev/null
}

mopidy_prev() {
    mopidy_rpc 'core.playback.previous' >/dev/null
}

mopidy_seek_percent() {
    local percent="$1"
    local duration_ms="$2"
    [[ "$percent" =~ ^[0-9]+([.][0-9]+)?$ ]] || return 1
    [[ "$duration_ms" =~ ^[0-9]+$ ]] || return 1
    (( duration_ms > 0 )) || return 1

    local target_ms
    target_ms=$(awk -v p="$percent" -v d="$duration_ms" 'BEGIN {printf "%d", (p * d) / 100}')
    mopidy_rpc 'core.playback.seek' "$(jq -cn --argjson t "$target_ms" '{time_position:$t}')" >/dev/null
}

get_mopidy_player_metadata() {
    if ! pgrep -x mopidy >/dev/null; then
        return
    fi

    local rpc_data current trackTime current_album current_album_date current_artist current_length current_title
    local format_album time_left cls state

    rpc_data=$(curl -sS --connect-timeout 1 --max-time 2 \
        -H 'Content-Type: application/json' \
        -d '[
            {"jsonrpc":"2.0","id":1,"method":"core.playback.get_state"},
            {"jsonrpc":"2.0","id":2,"method":"core.playback.get_current_tl_track"},
            {"jsonrpc":"2.0","id":3,"method":"core.playback.get_time_position"}
        ]' \
        "$MOPIDY_RPC_URL" 2>/dev/null)

    state=$(jq -r '.[] | select(.id == 1) | .result // empty' <<< "$rpc_data")
    [[ "$state" == "playing" || "$state" == "paused" ]] || return

    current=$(jq -c '.[] | select(.id == 2) | .result // empty' <<< "$rpc_data")
    trackTime=$(jq -r '.[] | select(.id == 3) | .result // 0' <<< "$rpc_data")
    [[ -n "$current" && "$current" != "null" ]] || return

    current_album=$(jq -r '.track.album.name // empty' <<< "$current")
    current_album_date=$(jq -r '.track.album.date // empty' <<< "$current")
    current_artist=$(jq -r '.track.artists[0].name // empty' <<< "$current")
    current_length=$(jq -r '.track.length // 0' <<< "$current")
    current_title=$(jq -r '.track.name // empty' <<< "$current")

    format_album="$current_album_date"
    [[ -n "$current_album" ]] && format_album+=" - $current_album"
    [[ -z "$format_album" ]] && format_album=""
    [[ -z "$current_artist" ]] && current_artist="music"

    time_left=$(timeFormat $((current_length - trackTime)))
    time_left=${time_left##00:}

    cls=$DEFAULT_TITLE_CLASS
    [[ ${#current_title} -gt 10 ]] && cls="more_ten"

    local status_icon="${icons[paused]}"
    [[ "$state" == "playing" ]] && status_icon="${icons[playing]}"

    local cover_image="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/album_cover.png"
    [[ -f "$cover_image" ]] || cover_image="$DEFAULT_IMG"

    get_json \
        --first_line "$current_title" \
        --second_line "$format_album" \
        --timeleft "$time_left" \
        --pos_ms "$trackTime" \
        --dur_ms "$current_length" \
        --status "$status_icon" \
        --image "$cover_image" \
        --artist "$current_artist" \
        --player "mopidy" \
        --title_class "$cls"
}
