#!/bin/bash
set -euo pipefail

get_main_volume() {
    local output raw_volume whole fraction padded_fraction fraction_pct third_digit percent muted
    if command -v wpctl >/dev/null 2>&1; then
        # wpctl is the preferred path on PipeWire desktops. Parse its one-line
        # response in Bash rather than starting AWK on each volume poll.
        output="$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)" || return $?
        read -r _ raw_volume _ <<< "$output"
        muted=0
        [[ "$output" == *"[MUTED]"* ]] && muted=1

        percent=0
        if [[ "${raw_volume:-}" =~ ^([0-9]+)([.]([0-9]+))?$ ]]; then
            whole="${BASH_REMATCH[1]}"
            fraction="${BASH_REMATCH[3]:-}"
            percent=$((10#$whole * 100))
            if [[ -n "$fraction" ]]; then
                # Round volume * 100 exactly as the previous AWK formatter did.
                # Two fractional digits give whole percent; the third decides
                # whether to round up. Padding keeps short decimal forms valid.
                padded_fraction="${fraction}00"
                fraction_pct=$((10#${padded_fraction:0:2}))
                third_digit="${padded_fraction:2:1}"
                if (( 10#$third_digit >= 5 )); then
                    fraction_pct=$((fraction_pct + 1))
                fi
                percent=$((percent + fraction_pct))
            fi
        fi
        printf '%s %s\n' "$percent" "$muted"
        return 0
    fi

    if command -v pactl >/dev/null 2>&1; then
        local volume_output mute_output vol=0 mute=0 line token last
        local -a tokens=()

        volume_output="$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null)" || return $?
        IFS= read -r line <<< "$volume_output" || true
        read -r -a tokens <<< "$line"
        for token in "${tokens[@]}"; do
            if [[ "$token" =~ ^([0-9]+)%$ ]]; then
                vol="${BASH_REMATCH[1]}"
                break
            fi
        done

        mute_output="$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null)" || return $?
        IFS= read -r line <<< "$mute_output" || true
        read -r -a tokens <<< "$line"
        if ((${#tokens[@]} > 0)); then
            last="${tokens[${#tokens[@]}-1]}"
            [[ "$last" == yes ]] && mute=1
        fi
        printf '%s %s\n' "$vol" "$mute"
        return 0
    fi

    if command -v amixer >/dev/null 2>&1; then
        local mixer_output mixer_line mixer_volume mixer_mute
        mixer_output="$(amixer -D pulse sget Master 2>/dev/null)" || return $?
        while IFS= read -r mixer_line; do
            [[ "$mixer_line" == *"Left:"* ]] || continue
            if [[ "$mixer_line" == *"off]"* ]]; then
                mixer_mute=1
            elif [[ "$mixer_line" == *"on]"* ]]; then
                mixer_mute=0
            else
                continue
            fi
            if [[ "$mixer_line" =~ \[([0-9]+)%?\] ]]; then
                mixer_volume="${BASH_REMATCH[1]}"
            else
                mixer_volume=0
            fi
            printf '%s %s\n' "$mixer_volume" "$mixer_mute"
            return 0
        done <<< "$mixer_output"
        return 0
    fi

    printf '0 0\n'
}

set_main_volume() {
    local value="$1"
    if command -v wpctl >/dev/null 2>&1; then
        wpctl set-volume @DEFAULT_AUDIO_SINK@ "${value}%"
    elif command -v pactl >/dev/null 2>&1; then
        pactl set-sink-volume @DEFAULT_SINK@ "${value}%"
    elif command -v amixer >/dev/null 2>&1; then
        amixer -D pulse sset Master "${value}%" >/dev/null
    else
        return 127
    fi
}

set_main_mute() {
    local muted="${1:-}"
    [[ "$muted" == "0" || "$muted" == "1" ]] || return 2

    if command -v wpctl >/dev/null 2>&1; then
        wpctl set-mute @DEFAULT_AUDIO_SINK@ "$muted"
    elif command -v pactl >/dev/null 2>&1; then
        pactl set-sink-mute @DEFAULT_SINK@ "$muted"
    elif command -v amixer >/dev/null 2>&1; then
        if [[ "$muted" == "1" ]]; then
            amixer -D pulse sset Master mute >/dev/null
        else
            amixer -D pulse sset Master unmute >/dev/null
        fi
    else
        return 127
    fi
}

toggle_main_mute() {
    if command -v wpctl >/dev/null 2>&1; then
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
    elif command -v pactl >/dev/null 2>&1; then
        pactl set-sink-mute @DEFAULT_SINK@ toggle
    elif command -v amixer >/dev/null 2>&1; then
        amixer -D pulse sset Master toggle >/dev/null
    else
        return 127
    fi
}
