#!/bin/bash

TIMER_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/timer"
IMG_PATH="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/desktop-shell-player"
MESSAGE="динь-динь"

timer_ensure_dirs() {
    [[ -d "$IMG_PATH" ]] || mkdir -p "$IMG_PATH"
    [[ -d "$TIMER_DIR" ]] || mkdir -p "$TIMER_DIR"
}

say() {
    [[ -n "$1" ]] && echo "$1" | festival --tts --language russian &>/dev/null &
}

get_color() {
    local hash r g b sum minSum=300

    hash=$(printf '%s' "$(date '+%s')$RANDOM" | md5sum | cut -c1-6)
    r=$((0x${hash:0:2}))
    g=$((0x${hash:2:2}))
    b=$((0x${hash:4:2}))
    sum=$((r + g + b))

    if (( sum < minSum )); then
        local diff=$(( (minSum - sum) / 3 + 1 ))
        r=$(( r + diff ))
        g=$(( g + diff ))
        b=$(( b + diff ))
    fi

    (( r > 255 )) && r=255
    (( g > 255 )) && g=255
    (( b > 255 )) && b=255

    printf '%02x%02x%02x\n' "$r" "$g" "$b"
}

json_escape() {
    local value="$1"
    value=${value//\\/\\\\}
    value=${value//\"/\\\"}
    value=${value//$'\n'/\\n}
    value=${value//$'\r'/\\r}
    printf '%s' "$value"
}

format_time() {
    local total_seconds=$1 hours minutes seconds time_str
    hours=$((total_seconds / 3600))
    minutes=$(((total_seconds % 3600) / 60))
    seconds=$((total_seconds % 60))
    printf -v time_str "%02d:%02d:%02d" "$hours" "$minutes" "$seconds"
    time_str=${time_str##00:}
    printf '%s\n' "$time_str"
}

read_timer_file() {
    local file="$1"
    [[ -f "$file" ]] || return 1
    read -r total_time end_time ding color paused_at comment < "$file"
}

write_timer_file() {
    local file="$1"
    echo "$total_time $end_time $ding $color $paused_at $comment" > "$file" || rm -f "$file"
}
