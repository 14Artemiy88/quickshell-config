#!/bin/bash

get_deadbeef_player_metadata() {
    # DeaDBeeF's process comm differs between packages/builds: some expose
    # `deadbeef-main`, while others expose `deadbeef`. Accept either exact
    # process name so the CLI backend is not silently skipped on distributions
    # that use the un-suffixed name. Try the common upstream name first and
    # only fall back to the alternate spelling if needed.
    if ! pgrep -x deadbeef-main >/dev/null 2>&1 && ! pgrep -x deadbeef >/dev/null 2>&1; then
        return
    fi

    local title status artist year album duration position timeleft file_path image_path meta meta_output separators
    title=$(deadbeef --nowplaying "%t" 2>/dev/null) || return
    # A running DeaDBeeF process does not necessarily mean a usable track is
    # available (the CLI can be starting, stopped, or temporarily unresponsive).
    # Do not emit a synthetic player payload in that case: scripts/player uses
    # the first valid backend result according to configured priority.
    [[ -n "${title//[[:space:]]/}" && "$title" != "nothing" ]] || return

    # Keep the known-compatible CLI format. Strip only its known startup banner
    # by taking the final output line, as older DeaDBeeF CLI versions may print
    # that banner before the metadata record.
    meta_output=$(deadbeef --nowplaying-tf '$if(%ispaused%,1,0)|%artist%|%year%|%album%|%length_seconds%|%playback_time_seconds%|-%playback_time_remaining%|%path%' 2>/dev/null) || return
    meta="${meta_output##*$'\n'}"
    [[ -n "$meta" ]] || return

    # This legacy CLI format is pipe-delimited. Fail closed if a response has
    # a missing/extra delimiter rather than misassigning fields and preventing
    # a later healthy backend from being selected.
    separators="${meta//[^|]/}"
    [[ ${#separators} -eq 7 ]] || return
    IFS='|' read -r status artist year album duration position timeleft file_path <<< "$meta"
    # DeaDBeeF title-formatting fields such as %ispaused% are conditional:
    # the raw field is present only while paused and is empty while playing.
    # The $if wrapper above normalizes both states to a numeric 0/1 value.
    [[ "$status" == "0" || "$status" == "1" ]] || return
    [[ "$duration" =~ ^[0-9]+([.][0-9]+)?$ ]] || return
    [[ "$position" =~ ^[0-9]+([.][0-9]+)?$ ]] || return

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

