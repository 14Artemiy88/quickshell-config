#!/bin/bash

TIMER_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/timer"
IMG_PATH="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/desktop-shell-player"
MESSAGE="динь-динь"

timer_ensure_dirs() {
    [[ -d "$IMG_PATH" ]] || mkdir -p "$IMG_PATH"
    [[ -d "$TIMER_DIR" ]] || mkdir -p "$TIMER_DIR"
}

# Timer files are shared by UI-triggered actions and the background daemon.
# Serialize every read/modify/write transaction with one stable lock file.
# It is hidden so the daemon's timer-file glob never treats it as a timer.
timer_with_lock() {
    local callback="$1" lock_fd status
    shift
    timer_ensure_dirs || return 1
    command -v flock >/dev/null 2>&1 || {
        printf 'timer: flock is required for safe timer state updates\n' >&2
        return 1
    }
    exec {lock_fd}>"$TIMER_DIR/.state.lock" || return 1
    flock -x "$lock_fd" || {
        exec {lock_fd}>&-
        return 1
    }
    "$callback" "$@"
    status=$?
    # The lock is attached to the shared open-file description. Closing the
    # last descriptor releases it, so launching a second external `flock -u`
    # process here is unnecessary on every timer poll/action.
    exec {lock_fd}>&-
    return "$status"
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

# Escape a JSON string directly into a caller variable. The timer daemon runs
# this twice for every timer on every one-second poll; command substitution
# around json_escape would create two subshells per timer per cycle.
json_escape_into() {
    local output_var="$1" value="${2-}" char escaped_char out="" i code
    local LC_ALL=C
    for ((i = 0; i < ${#value}; i++)); do
        char="${value:i:1}"
        case "$char" in
            $'\\') out+='\\' ;;
            '"') out+='\"' ;;
            $'\b') out+='\b' ;;
            $'\f') out+='\f' ;;
            $'\n') out+='\n' ;;
            $'\r') out+='\r' ;;
            $'\t') out+='\t' ;;
            *)
                printf -v code '%d' "'$char"
                if (( code < 32 || code == 127 )); then
                    printf -v escaped_char '\\u%04x' "$code"
                    out+="$escaped_char"
                else
                    out+="$char"
                fi
                ;;
        esac
    done
    printf -v "$output_var" '%s' "$out"
}

# Preserve the stdout-based interface for existing callers.
json_escape() {
    local encoded_result
    json_escape_into encoded_result "${1-}"
    printf '%s' "$encoded_result"
}

# Wrap already-serialized timer records in a JSON array without launching jq
# on every daemon tick. Entries are produced by timer_process_entry_locked,
# which owns JSON escaping for all string fields. The caller-variable variant
# lets the daemon assemble its batch while holding the shared state lock without
# a command-substitution subshell.
timer_entries_to_json_into() {
    local output_var="$1" serialized_json='[' entry first=1
    shift
    for entry in "$@"; do
        (( first )) || serialized_json+=,
        serialized_json+="$entry"
        first=0
    done
    serialized_json+=']'
    printf -v "$output_var" '%s' "$serialized_json"
}

timer_entries_to_json() {
    local result
    timer_entries_to_json_into result "$@"
    printf '%s\n' "$result"
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

# Assign the formatted value directly in the caller's scope. The timer daemon
# runs this twice per timer entry per tick; command substitution around
# format_time would otherwise fork a subshell for each value.
format_time_into() {
    local output_var="$1" total_seconds="$2" hours minutes seconds time_str
    hours=$((total_seconds / 3600))
    minutes=$(((total_seconds % 3600) / 60))
    seconds=$((total_seconds % 60))
    printf -v time_str "%02d:%02d:%02d" "$hours" "$minutes" "$seconds"
    time_str=${time_str##00:}
    printf -v "$output_var" '%s' "$time_str"
}

read_timer_file() {
    local file="$1"
    [[ -f "$file" ]] || return 1
    IFS=' ' read -r total_time end_time ding color paused_at comment < "$file"
}

# Publish complete timer records atomically. Readers never observe a truncated
# file, even if Quickshell or the daemon is interrupted during an update.
write_timer_file() {
    local file="$1" temp
    temp=$(mktemp "$TIMER_DIR/.timer-write.XXXXXX") || return 1
    if ! printf '%s %s %s %s %s %s\n' "$total_time" "$end_time" "$ding" "$color" "$paused_at" "$comment" > "$temp"; then
        rm -f "$temp"
        return 1
    fi
    # mktemp creates a private 0600 file already; do not spawn chmod on
    # every daemon tick or timer action before publishing it atomically.
    if ! mv -f -- "$temp" "$file"; then
        rm -f "$temp"
        return 1
    fi
}

timer_create_file() {
    local file="$1" contents="$2" temp
    temp=$(mktemp "$TIMER_DIR/.timer-create.XXXXXX") || return 1
    if ! printf '%s\n' "$contents" > "$temp"; then
        rm -f "$temp"
        return 1
    fi
    # mktemp creates a private 0600 file already; retain that mode through
    # the atomic rename without an additional chmod process.
    if ! mv -f -- "$temp" "$file"; then
        rm -f "$temp"
        return 1
    fi
}
