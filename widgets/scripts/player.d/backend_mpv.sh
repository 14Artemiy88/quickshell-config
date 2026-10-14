#!/bin/bash

get_mpv_player_metadata() {
    if ! pgrep -x mpv >/dev/null; then
        return
    fi

    local mpvsocket="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/mpvsocket"
    [[ ! -S "$mpvsocket" ]] && return

    local mpv_data title position duration path remaining timeleft field
    local -a mpv_fields=()

    mpv_data=$(socat - "$mpvsocket" <<< $'{"command": ["get_property_string", "media-title"], "request_id": 1}\n{"command": ["get_property", "time-pos"], "request_id": 2}\n{"command": ["get_property", "duration"], "request_id": 3}\n{"command": ["get_property", "path"], "request_id": 4}')

    # mpv returns four independent JSON documents. Extract them in one jq
    # process, emitting NUL-delimited fields so whitespace/newlines in titles
    # cannot shift the position, duration, or path columns.
    while IFS= read -r -d '' field; do
        mpv_fields+=("$field")
    done < <(jq -jrs '
        def field($id):
            [ .[] | select(.request_id == $id) |
                if has("data") then
                    if .data == null then "null" else (.data | tostring) end
                else "" end
            ][0] // "";
        [field(1), field(2), field(3), field(4)][] + "\u0000"
    ' <<< "$mpv_data")
    [[ ${#mpv_fields[@]} -eq 4 ]] || return
    title="${mpv_fields[0]}"
    position="${mpv_fields[1]}"
    duration="${mpv_fields[2]}"
    path="${mpv_fields[3]}"

    # A live mpv process/socket can exist while the IPC response is incomplete
    # (startup, track transition, or a transient IPC failure). Do not emit a
    # synthetic mpv payload: the dispatcher must be able to try the next player.
    local numeric_re='^[0-9]+([.][0-9]+)?$'
    [[ -n "${title//[[:space:]]/}" && "$title" != "null" ]] || return
    [[ "$position" =~ $numeric_re ]] || return

    # Some live streams do not expose a duration. Keep their metadata, but do
    # not invent a zero countdown or a progress range until duration is known.
    if [[ "$duration" == "null" || -z "$duration" ]]; then
        duration=""
        timeleft=""
    elif [[ "$duration" =~ $numeric_re ]]; then
        # Combine duration validation and remaining-time arithmetic. The
        # previous path started awk twice on every mpv poll just to check d>0
        # and then calculate max(d-position, 0).
        remaining=$(awk -v d="$duration" -v p="$position" 'BEGIN {
            if (d <= 0) exit 1
            r = d - p
            if (r < 0) r = 0
            printf "%.0f", r
        }') || remaining=""
        if [[ -n "$remaining" ]]; then
            timeleft=$(date -u -d @"$remaining" +'%H:%M:%S') || timeleft=""
            timeleft=${timeleft##00:}
        else
            # A zero duration is another common representation of an unknown
            # length for live streams. Keep metadata without a fake countdown.
            duration=""
            timeleft=""
        fi
    else
        return
    fi

    [[ "$path" == "null" ]] && path=""

    # Preserve metadata literally; get_json handles JSON escaping via jq.

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
