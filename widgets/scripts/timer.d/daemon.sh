#!/bin/bash

# Read, render and apply the expiration transition under the same lock used by
# UI actions. This prevents a stale daemon snapshot from overwriting a pause,
# extension, comment edit or deletion.
timer_process_entry() {
    local status=0
    # JSON is streamed through while the callback holds the lock. A special
    # return code reports a new expiration, so speech starts only after unlock
    # without adding a second nested command-substitution process.
    timer_with_lock timer_process_entry_locked "$1" "$2" || status=$?
    if (( status == 10 )); then
        say "$MESSAGE"
        return 0
    fi
    return "$status"
}

timer_process_entry_locked() {
    local file="$1" now="$2"
    local total_time end_time ding color paused_at comment
    local seconds_left display_now sign timer_str time_passed comment_json file_json

    read_timer_file "$file" || return 0

    display_now=$now
    if (( paused_at > 0 )); then
        display_now=$paused_at
    fi

    seconds_left=$((end_time - display_now))
    sign=""
    if (( total_time > 0 && seconds_left < 0 )); then
        sign=" + "
    fi

    if (( total_time > 0 && seconds_left <= 0 && ding == 0 )); then
        ding=1
        write_timer_file "$file" || return 1
        local ding_transition=1
    else
        local ding_transition=0
    fi

    [[ -z "$comment" ]] && comment="$total_time"
    timer_str="PAUSED"
    if (( paused_at == 0 )); then
        timer_str=$(format_time "${seconds_left#-}")
    fi

    time_passed=$(format_time $((total_time * 60 - seconds_left)))
    comment_json=$(json_escape "$comment")
    file_json=$(json_escape "$file")
    printf '{"file":"%s", "comment":"%s", "timer":"%s", "color":"#%s", "sign":"%s", "time_passed":"%s", "ding":%s}' \
        "$file_json" "$comment_json" "$timer_str" "$color" "$sign" "$time_passed" "$ding"
    if (( ding_transition )); then
        return 10
    fi
    return 0
}

run_daemon() {
    local now file data
    local -a timers=()
    timer_ensure_dirs || return 1

    while true; do
        now=$(date '+%s')
        timers=()

        # Read fresh state for every timer each cycle. The old second-resolution
        # mtime cache could miss two writes in the same second and replay stale
        # data over newer user actions.
        for file in "$TIMER_DIR"/*; do
            [[ -f "$file" ]] || continue
            data=$(timer_process_entry "$file" "$now") || continue
            [[ -n "$data" ]] && timers+=("$data")
        done

        if (( ${#timers[@]} > 0 )); then
            printf '%s\n' "${timers[@]}" | jq -s -c .
        else
            echo '[]'
        fi

        sleep 1
    done
}
