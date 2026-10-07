#!/bin/bash

timer_up() {
    local file="$1"
    read_timer_file "$file" || return
    end_time=$((end_time + 60))
    local now
    now=$(date '+%s')
    ding=$((end_time - now <= 0))
    total_time=$((total_time + 1))
    write_timer_file "$file"
}

timer_down() {
    local file="$1"
    read_timer_file "$file" || return
    end_time=$((end_time - 60))
    total_time=$((total_time - 1))
    local now
    now=$(date '+%s')
    (( end_time > now )) && write_timer_file "$file"
}

timer_delete() {
    rm -f "$1"
}

timer_add_at() {
    local target="$1"
    [[ "$target" =~ ^([01][0-9]|2[0-3]):[0-5][0-9]$ ]] || return 1

    timer_ensure_dirs

    local now target_epoch delta minutes file
    now=$(date '+%s')
    target_epoch=$(date -d "today $target" '+%s') || return 1
    if (( target_epoch <= now )); then
        target_epoch=$(date -d "tomorrow $target" '+%s') || return 1
    fi
    delta=$((target_epoch - now))
    minutes=$(( (delta + 59) / 60 ))
    file="$TIMER_DIR/${now}_$RANDOM"
    echo "$minutes $target_epoch 0 $(get_color) 0 $target" > "$file"
}

timer_add() {
    timer_ensure_dirs

    local file now
    now=$(date '+%s')
    file="$TIMER_DIR/${now}_$RANDOM"
    echo "$1 $(date -d "+$1 min" +%s ) 0 $(get_color) 0 $2" > "$file"
}

update_color() {
    local file="$1"
    read_timer_file "$file" || return
    color=$(get_color)
    write_timer_file "$file"
}

set_comment() {
    local file="$1"
    local new_comment="$2"
    read_timer_file "$file" || return
    comment="$new_comment"
    write_timer_file "$file"
}

refresh() {
    local file="$1"
    read_timer_file "$file" || return
    ding=0
    end_time=$(date -d "+$total_time min" +%s)
    write_timer_file "$file"
}

refresh_add() {
    local file="$1"
    read_timer_file "$file" || return
    ding=0
    comment="$total_time"
    end_time=$(date -d "+$total_time min" +%s)
    write_timer_file "$file"
}

toggle_pause() {
    local file="$1"
    read_timer_file "$file" || return
    local now
    now=$(date '+%s')
    if (( paused_at == 0 )); then
        paused_at=$now
    else
        local paused_duration=$((now - paused_at))
        end_time=$((end_time + paused_duration))
        paused_at=0
    fi
    write_timer_file "$file"
}
