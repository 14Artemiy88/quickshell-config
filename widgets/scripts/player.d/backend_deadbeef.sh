#!/bin/bash

get_deadbeef_player_metadata() {
    if ! pgrep -x deadbeef-main >/dev/null; then
        return
    fi

    local title status artist year album duration position timeleft file_path image_path meta
    title=$(deadbeef --nowplaying "%t" 2>/dev/null)
    [[ "$title" == "nothing" ]] && return

    # Один вызов для всех остальных данных (tail -1 фильтрует "starting deadbeef...")
    meta=$(deadbeef --nowplaying-tf '%ispaused%|%artist%|%year%|%album%|%length_seconds%|%playback_time_seconds%|-%playback_time_remaining%|%path%' 2>/dev/null | tail -1)
    IFS='|' read -r status artist year album duration position timeleft file_path <<< "$meta"

    [[ "$status" == "1" ]] && status="Paused" || status="Playing"

    # Формируем строку альбома: "год - альбом" или просто альбом
    [[ -n "$year" && "$year" != "0" ]] && album="$year - $album"

    if [[ -f "$file_path" ]]; then
        image_path=$(get_album_img "$file_path")
    fi

    get_json \
        --first_line "$artist" \
        --second_line "$album" \
        --third_line "$title" \
        --timeleft "$timeleft" \
        --pos_ms "${position%%.*}000" \
        --dur_ms "${duration%%.*}000" \
        --status "${icons[$status]}" \
        --image "$image_path" \
        --artist "$artist" \
        --player "deadbeef"
}

