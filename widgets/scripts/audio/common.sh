#!/bin/bash
set -euo pipefail

get_main_volume() {
    if command -v wpctl >/dev/null 2>&1; then
        wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{v=$2*100; muted=(/MUTED/)?1:0; printf "%d %d\n", v+0.5, muted; exit}'
        return
    fi

    if command -v pactl >/dev/null 2>&1; then
        local vol mute
        vol=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | awk 'NR==1 { for (i=1;i<=NF;i++) if ($i ~ /^[0-9]+%$/) { gsub(/%/, "", $i); print $i; exit } }')
        mute=$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | awk '{print ($NF=="yes") ? 1 : 0; exit}')
        printf "%s %s\n" "${vol:-0}" "${mute:-0}"
        return
    fi

    if command -v amixer >/dev/null 2>&1; then
        amixer -D pulse sget Master 2>/dev/null | awk -F"[][]" '/Left:/ { if (/off\]/) { print $2+0, 1; exit } if (/on\]/) { gsub(/%/, "", $2); print $2+0, 0; exit } }'
        return
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
