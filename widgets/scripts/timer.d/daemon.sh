#!/bin/bash

declare -A t_mtime
declare -A t_data
declare -a timer_files=()

run_daemon() {
    local now timers json file mtime data total_time end_time ding color paused_at comment
    local seconds_left display_now sign timer_str time_passed

    while true; do
        now=$(date '+%s')
        timers=()
        timer_files=()

        for file in "$TIMER_DIR"/*; do
            [[ -f "$file" ]] || continue
            timer_files+=("$file")

            mtime=$(stat -c %Y "$file" 2>/dev/null)
            if [[ "${t_mtime[$file]}" != "$mtime" ]]; then
                read_timer_file "$file"
                t_mtime["$file"]="$mtime"
                t_data["$file"]="$total_time:$end_time:$ding:$color:$paused_at:$comment"
            else
                data="${t_data[$file]}"
                total_time="${data%%:*}"; data="${data#*:}"
                end_time="${data%%:*}";   data="${data#*:}"
                ding="${data%%:*}";       data="${data#*:}"
                color="${data%%:*}";      data="${data#*:}"
                paused_at="${data%%:*}";  comment="${data#*:}"
            fi

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
                t_data["$file"]="$total_time:$end_time:$ding:$color:$paused_at:$comment"
                write_timer_file "$file"
                say "$MESSAGE"
            fi

            [[ -z "$comment" ]] && comment="$total_time"

            timer_str="PAUSED"
            if (( paused_at == 0 )); then
                timer_str=$(format_time "${seconds_left#-}")
            fi

            time_passed=$(format_time $((total_time * 60 - seconds_left)))
            local comment_json
            comment_json=$(json_escape "$comment")
            timers+=(
              "{\"file\":\"$file\", \"comment\":\"$comment_json\", \"timer\":\"$timer_str\", \"color\":\"#$color\", \"sign\":\"$sign\", \"time_passed\":\"$time_passed\", \"ding\":$ding}"
            )
        done

        for key in "${!t_mtime[@]}"; do
            [[ -f "$key" ]] || { unset 't_mtime[$key]'; unset 't_data[$key]'; }
        done

        if (( ${#timers[@]} > 0 )); then
            printf '%s\n' "${timers[@]}" | jq -s -c .
        else
            echo '[]'
        fi

        sleep 1
    done
}
