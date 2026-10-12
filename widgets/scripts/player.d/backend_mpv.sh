#!/bin/bash

get_mpv_player_metadata() {
    if ! pgrep -x mpv >/dev/null; then
        return
    fi

    local mpvsocket="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/mpvsocket"
    [[ ! -S "$mpvsocket" ]] && return

    local mpv_data title position duration path remaining timeleft
    
    mpv_data=$(socat - "$mpvsocket" <<< $'{"command": ["get_property_string", "media-title"], "request_id": 1}\n{"command": ["get_property", "time-pos"], "request_id": 2}\n{"command": ["get_property", "duration"], "request_id": 3}\n{"command": ["get_property", "path"], "request_id": 4}')

    title=$(jq -r 'select(.request_id == 1) | .data' <<< "$mpv_data")
    position=$(jq -r 'select(.request_id == 2) | .data' <<< "$mpv_data")
    duration=$(jq -r 'select(.request_id == 3) | .data' <<< "$mpv_data")
    path=$(jq -r 'select(.request_id == 4) | .data' <<< "$mpv_data")

    [[ -z "$position" || "$position" == "null" ]] && return

    # Рассчитываем оставшееся время
    remaining=$(awk -v d="$duration" -v p="$position" 'BEGIN {printf "%.0f", d - p}')
    timeleft=$(date -u -d @"$remaining" +'%H:%M:%S')
    timeleft=${timeleft##00:}

    title="${title//\"/}"

    # Refresh the current video frame at most once per minute. Snapshot names
    # are keyed by media path (not title) and versioned so QtQuick.Image sees
    # a new URL after each refresh. On capture failure, the last valid frame is
    # retained; with no previous frame, use the transparent fallback.
    local image_path
    image_path=$(get_mpv_snapshot "$path" "$position" false 60) || image_path=""
    [[ -s "$image_path" ]] || image_path="$DEFAULT_IMG"


    get_json \
        --first_line "$title" \
        --timeleft "$timeleft" \
        --pos_ms "${position%%.*}" \
        --dur_ms "${duration%%.*}" \
        --image "$image_path" \
        --artist "$DEFAULT_TEXT" \
        --player "mpv"
}

# Получение метаданных через playerctl
