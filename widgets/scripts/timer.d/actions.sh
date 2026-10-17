#!/bin/bash

timer_up()       { timer_with_lock timer_up_locked "$1" "${2:-1}"; }
timer_down()     { timer_with_lock timer_down_locked "$1" "${2:-1}"; }
timer_delete()   { timer_with_lock timer_delete_locked "$1"; }
timer_add_at()   { timer_with_lock timer_add_at_locked "$1"; }
timer_add()      { timer_with_lock timer_add_locked "$1" "$2"; }
update_color()   { timer_with_lock update_color_locked "$1"; }
set_comment()    { timer_with_lock set_comment_locked "$1" "$2"; }
refresh()        { timer_with_lock refresh_locked "$1"; }
refresh_add()    { timer_with_lock refresh_add_locked "$1"; }
toggle_pause()   { timer_with_lock toggle_pause_locked "$1"; }

timer_up_locked() {
    local file="$1" step="${2:-1}"
    [[ "$step" =~ ^[0-9]+$ ]] || step=1
    (( step < 1 )) && step=1
    (( step > 60 )) && step=60
    read_timer_file "$file" || return 1
    end_time=$((end_time + 60 * step))
    local now
    now=$(date '+%s')
    ding=$((end_time - now <= 0))
    total_time=$((total_time + step))
    write_timer_file "$file"
}

timer_down_locked() {
    local file="$1" step="${2:-1}"
    [[ "$step" =~ ^[0-9]+$ ]] || step=1
    (( step < 1 )) && step=1
    (( step > 60 )) && step=60
    read_timer_file "$file" || return 1
    end_time=$((end_time - 60 * step))
    total_time=$((total_time - step))
    local now
    now=$(date '+%s')
    if (( end_time > now )); then
        write_timer_file "$file"
    else
        return 0
    fi
}

timer_delete_locked() {
    rm -f -- "$1"
}

timer_add_at_locked() {
    local target="$1"
    [[ "$target" =~ ^([01][0-9]|2[0-3]):[0-5][0-9]$ ]] || return 1

    local now target_epoch delta minutes file contents
    now=$(date '+%s')
    target_epoch=$(date -d "today $target" '+%s') || return 1
    if (( target_epoch <= now )); then
        target_epoch=$(date -d "tomorrow $target" '+%s') || return 1
    fi
    delta=$((target_epoch - now))
    minutes=$(( (delta + 59) / 60 ))
    file="$TIMER_DIR/${now}_$RANDOM"
    contents="$minutes $target_epoch 0 $(get_color) 0 $target"
    timer_create_file "$file" "$contents"
}

timer_add_locked() {
    local minutes="$1" comment="$2" now file end contents
    [[ "$minutes" =~ ^[0-9]+$ ]] || return 1
    now=$(date '+%s')
    end=$(date -d "+$minutes min" +%s) || return 1
    file="$TIMER_DIR/${now}_$RANDOM"
    contents="$minutes $end 0 $(get_color) 0 $comment"
    timer_create_file "$file" "$contents"
}

update_color_locked() {
    local file="$1"
    read_timer_file "$file" || return 1
    color=$(get_color)
    write_timer_file "$file"
}

set_comment_locked() {
    local file="$1" new_comment="$2"
    read_timer_file "$file" || return 1
    comment="$new_comment"
    write_timer_file "$file"
}

refresh_locked() {
    local file="$1"
    read_timer_file "$file" || return 1
    ding=0
    end_time=$(date -d "+$total_time min" +%s) || return 1
    write_timer_file "$file"
}

refresh_add_locked() {
    local file="$1"
    read_timer_file "$file" || return 1
    ding=0
    comment="$total_time"
    end_time=$(date -d "+$total_time min" +%s) || return 1
    write_timer_file "$file"
}

toggle_pause_locked() {
    local file="$1"
    read_timer_file "$file" || return 1
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
