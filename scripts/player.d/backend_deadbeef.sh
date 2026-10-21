#!/bin/bash

get_deadbeef_player_metadata() {
    # DeaDBeeF's process comm differs between packages/builds: some expose
    # `deadbeef-main`, while others expose `deadbeef`. pgrep accepts an extended
    # regular expression with -x, so match either complete name in one launch
    # rather than probing each spelling with a separate process.
    if ! pgrep -x 'deadbeef(-main)?' >/dev/null 2>&1; then
        return
    fi

    local title status artist year album duration position timeleft file_path image_path meta meta_output
    # Read the track title and all other metadata in one CLI invocation. The
    # title is deliberately the final field so a literal pipe in the title is
    # preserved by Bash's last read variable rather than shifting other fields.
    # Strip only the known startup banner used by older DeaDBeeF builds.
    meta_output=$(deadbeef --nowplaying-tf '$if(%ispaused%,1,0)|%artist%|%year%|%album%|%length_seconds%|%playback_time_seconds%|-%playback_time_remaining%|%path%|%title%' 2>/dev/null) || return
    meta="$meta_output"
    # Strip the known startup banner only when it is the first line. Keep the
    # rest intact because a track title itself may contain embedded newlines.
    if [[ "$meta" == *$'\n'* && "${meta%%$'\n'*}" == starting\ deadbeef* ]]; then
        meta="${meta#*$'\n'}"
    fi
    [[ -n "$meta" ]] || return

    # Consume exactly the eight fixed separators using parameter expansion.
    # This preserves a pipe or newline in the final title field. Malformed
    # earlier fields remain fail-closed through the status/numeric checks.
    [[ "$meta" == *'|'* ]] || return; status="${meta%%|*}"; meta="${meta#*|}"
    [[ "$meta" == *'|'* ]] || return; artist="${meta%%|*}"; meta="${meta#*|}"
    [[ "$meta" == *'|'* ]] || return; year="${meta%%|*}"; meta="${meta#*|}"
    [[ "$meta" == *'|'* ]] || return; album="${meta%%|*}"; meta="${meta#*|}"
    [[ "$meta" == *'|'* ]] || return; duration="${meta%%|*}"; meta="${meta#*|}"
    [[ "$meta" == *'|'* ]] || return; position="${meta%%|*}"; meta="${meta#*|}"
    [[ "$meta" == *'|'* ]] || return; timeleft="${meta%%|*}"; meta="${meta#*|}"
    [[ "$meta" == *'|'* ]] || return; file_path="${meta%%|*}"; title="${meta#*|}"
    # A running DeaDBeeF process does not necessarily mean a usable track is
    # available (the CLI can be starting, stopped, or temporarily unresponsive).
    # Do not emit a synthetic player payload in that case: scripts/player uses
    # the first valid backend result according to configured priority.
    [[ -n "${title//[[:space:]]/}" && "$title" != "nothing" ]] || return
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

