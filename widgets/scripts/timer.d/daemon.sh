#!/bin/bash

# Read, render and apply the expiration transition under the same lock used by
# UI actions. This prevents a stale daemon snapshot from overwriting a pause,
# extension, comment edit or deletion.
# Assign a timer entry's serialized JSON directly into the caller's variable.
# The daemon polls every timer each second; capturing timer_process_entry stdout
# with command substitution would fork one subshell per active timer per tick.
timer_process_entry_into() {
    local output_var="$1" status=0
    shift
    printf -v "$output_var" '%s' ''
    # JSON is assembled while the callback holds the lock. A special return
    # code reports a new expiration, so speech starts only after the lock ends.
    timer_with_lock timer_process_entry_locked "$output_var" "$1" "$2" || status=$?
    if (( status == 10 )); then
        say "$MESSAGE"
        return 0
    fi
    return "$status"
}

# Preserve the stdout-based interface for callers and existing integrations.
timer_process_entry() {
    local entry status=0
    timer_process_entry_into entry "$1" "$2" || status=$?
    [[ -n "$entry" ]] && printf '%s' "$entry"
    return "$status"
}

timer_process_entry_locked() {
    local output_var="$1" file="$2" now="$3"
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
        format_time_into timer_str "${seconds_left#-}"
    fi

    format_time_into time_passed $((total_time * 60 - seconds_left))
    json_escape_into comment_json "$comment"
    json_escape_into file_json "$file"
    local json_record
    printf -v json_record '{"file":"%s","comment":"%s","timer":"%s","color":"#%s","sign":"%s","time_passed":"%s","ding":%s}' \
        "$file_json" "$comment_json" "$timer_str" "$color" "$sign" "$time_passed" "$ding"
    printf -v "$output_var" '%s' "$json_record"
    if (( ding_transition )); then
        return 10
    fi
    return 0
}


# Build a whole timer snapshot under one shared lock per daemon tick. Every
# entry is still read afresh, and expiration transitions are committed while
# UI actions are excluded; this keeps the no-stale-snapshot guarantee while
# replacing one external `flock` process per timer with one per snapshot.
# The number of expirations is returned separately so speech only starts after
# timer_with_lock has closed its descriptor and released the lock.
timer_process_batch_locked() {
    local output_var="$1" expired_var="$2" now="$3"
    local file data status result_json expired_count=0
    local -a entries=()

    for file in "$TIMER_DIR"/*; do
        [[ -f "$file" ]] || continue
        data=''
        status=0
        timer_process_entry_locked data "$file" "$now" || status=$?
        [[ -n "$data" ]] && entries+=("$data")
        if (( status == 10 )); then
            expired_count=$((expired_count + 1))
        fi
    done

    timer_entries_to_json_into result_json "${entries[@]}"
    printf -v "$output_var" '%s' "$result_json"
    printf -v "$expired_var" '%d' "$expired_count"
}

run_daemon() {
    local now tick_payload tick_expirations i
    timer_ensure_dirs || return 1

    while true; do
        # Bash 5+ exposes EPOCHSECONDS as a built-in clock value. Use it on
        # every one-second daemon tick to avoid spawning `date`; retain the
        # external fallback for older Bash versions.
        now=${EPOCHSECONDS:-}
        if [[ ! "$now" =~ ^[0-9]+$ ]]; then
            now=$(date '+%s')
        fi

        tick_payload=''
        tick_expirations=0
        # One lock covers the full snapshot, including expiry-state updates.
        # UI actions can therefore never be overwritten by a stale scan, while
        # the daemon launches flock once per tick rather than once per timer.
        if ! timer_with_lock timer_process_batch_locked tick_payload tick_expirations "$now"; then
            tick_payload='[]'
            tick_expirations=0
        fi
        [[ -n "$tick_payload" ]] || tick_payload='[]'
        printf '%s\n' "$tick_payload"

        # Never run the speech command while holding the shared timer lock.
        for ((i = 0; i < tick_expirations; i++)); do
            say "$MESSAGE"
        done

        sleep 1
    done
}
