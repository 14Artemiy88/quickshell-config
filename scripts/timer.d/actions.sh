#!/bin/bash

timer_up()       { timer_with_lock timer_up_locked "$1" "${2:-1}"; }
timer_down()     { timer_with_lock timer_down_locked "$1" "${2:-1}"; }
timer_set_duration() { timer_with_lock timer_set_duration_locked "$1" "$2"; }
timer_delete()   { timer_with_lock timer_delete_locked "$1"; }
timer_add_at()   { timer_with_lock timer_add_at_locked "$1" "$2" "$3" "$4"; }
timer_add()      { timer_with_lock timer_add_locked "$1" "$2" "$3" "$4" "$5"; }
update_color()   { timer_with_lock update_color_locked "$1" "$2" "$3" "$4"; }
set_color()      { timer_with_lock set_color_locked "$1" "$2"; }
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

# Start a fresh countdown interval while preserving the timer's cumulative
# elapsed counter. The completed/partial interval is folded into a sidecar;
# the new interval starts at zero without resetting the total session time.
timer_restart_interval_locked() {
    local file="$1" new_total="$2" base_now seconds_left interval_elapsed new_offset
    local old_total="$total_time" old_end="$end_time" old_ding="$ding" old_offset="$timer_elapsed_offset"

    base_now=$(date '+%s')
    if (( paused_at > 0 )); then
        base_now=$paused_at
    fi

    seconds_left=$((end_time - base_now))
    interval_elapsed=$((total_time * 60 - seconds_left))
    (( interval_elapsed < 0 )) && interval_elapsed=0
    new_offset=$((timer_elapsed_offset + interval_elapsed))

    total_time=$new_total
    end_time=$((base_now + new_total * 60))
    ding=0

    if ! write_timer_elapsed_offset "$file" "$new_offset"; then
        total_time=$old_total
        end_time=$old_end
        ding=$old_ding
        return 1
    fi
    if ! write_timer_file "$file"; then
        total_time=$old_total
        end_time=$old_end
        ding=$old_ding
        write_timer_elapsed_offset "$file" "$old_offset" || true
        return 1
    fi
}

# Editing duration starts a new countdown from the requested duration. Any
# elapsed time from the previous interval remains in the cumulative counter.
timer_set_duration_locked() {
    local file="$1" requested="${2:-}" new_total
    [[ "$requested" =~ ^[0-9]{1,5}$ ]] || return 1
    new_total=$((10#$requested))
    (( new_total >= 1 && new_total <= 10080 )) || return 1
    read_timer_file "$file" || return 1
    timer_restart_interval_locked "$file" "$new_total"
}

timer_delete_locked() {
    local file="$1"
    rm -f -- "$file" "$TIMER_DIR/.elapsed-${file##*/}"
}

timer_add_at_locked() {
    local target="$1" color_mode="${2:-full}" color_min="${3:-#000000}" color_max="${4:-#ffffff}"
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
    contents="$minutes $target_epoch 0 $(get_color "$color_mode" "$color_min" "$color_max") 0 $target"
    timer_create_file "$file" "$contents"
}

timer_add_locked() {
    local minutes="$1" comment="$2" color_mode="${3:-full}" color_min="${4:-#000000}" color_max="${5:-#ffffff}" now file end contents
    [[ "$minutes" =~ ^[0-9]+$ ]] || return 1
    now=$(date '+%s')
    end=$(date -d "+$minutes min" +%s) || return 1
    file="$TIMER_DIR/${now}_$RANDOM"
    contents="$minutes $end 0 $(get_color "$color_mode" "$color_min" "$color_max") 0 $comment"
    timer_create_file "$file" "$contents"
}

update_color_locked() {
    local file="$1" color_mode="${2:-full}" color_min="${3:-#000000}" color_max="${4:-#ffffff}"
    read_timer_file "$file" || return 1
    color=$(get_color "$color_mode" "$color_min" "$color_max")
    write_timer_file "$file"
}

set_color_locked() {
    local file="$1" requested="${2:-}"
    requested="${requested#\#}"
    [[ "$requested" =~ ^[0-9a-fA-F]{6}$ ]] || return 1
    read_timer_file "$file" || return 1
    color="${requested,,}"
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
    timer_restart_interval_locked "$file" "$total_time"
}

refresh_add_locked() {
    local file="$1" duration old_comment
    read_timer_file "$file" || return 1
    duration="$total_time"
    old_comment="$comment"
    comment="$total_time"
    if ! timer_restart_interval_locked "$file" "$duration"; then
        comment="$old_comment"
        return 1
    fi
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
