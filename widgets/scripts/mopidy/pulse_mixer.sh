#!/bin/bash
# Fast per-stream mute for Mopidy when its playback stream is routed through
# PulseAudio or PipeWire's PulseAudio compatibility server. This file is
# sourced by mixer.sh and status.sh; it does not run actions when sourced.

mopidy_pulse_parse_sink_inputs() {
    command -v pactl >/dev/null 2>&1 || return 1
    local listing
    listing="$(pactl list sink-inputs 2>/dev/null)" || return 1
    [[ -n "$listing" ]] || return 1
    printf '%s\n' "$listing" | awk '
        # Use ASCII unit separator, not tabs: Bash treats tabs as IFS whitespace
        # and collapses empty columns. That used to shift application PID into
        # the wrong field when pactl omitted application.name or process.binary.
        function prop(line, key, p, value) {
            p = index(line, key " = ")
            if (!p) return ""
            value = substr(line, p + length(key " = "))
            sub(/^[[:space:]]+/, "", value)
            if (substr(value, 1, 1) == "\"") {
                value = substr(value, 2)
                sub(/".*$/, "", value)
            } else {
                sub(/[[:space:]].*$/, "", value)
            }
            return value
        }
        function emit() {
            if (id != "")
                printf "%s\034%s\034%s\034%s\034%s\034%s\n", id, mute, app, binary, pid, media_name
        }
        /^Sink Input #[0-9]+|^Вход аудиоприёмника №[0-9]+/ {
            emit()
            id = $0
            if (id ~ /^Sink Input #/) sub(/^Sink Input #/, "", id)
            else sub(/^Вход аудиоприёмника №/, "", id)
            sub(/[[:space:]].*$/, "", id)
            mute = ""
            app = ""
            binary = ""
            pid = ""
            media_name = ""
            next
        }
        /^[[:space:]]*(Mute:|Заглушен:|Отключён:|Без звука:)/ {
            mute = $0
            sub(/^[[:space:]]*(Mute:|Заглушен:|Отключён:|Без звука:)[[:space:]]*/, "", mute)
            mute = tolower(mute)
            if (mute != "yes" && mute != "да" && mute != "true" && mute != "1") mute = "no"
            else mute = "yes"
            next
        }
        /application\.name[[:space:]]*=/ { app = prop($0, "application.name"); next }
        /application\.process\.binary[[:space:]]*=/ { binary = prop($0, "application.process.binary"); next }
        /application\.process\.id[[:space:]]*=/ { pid = prop($0, "application.process.id"); next }
        /media\.name[[:space:]]*=/ { media_name = prop($0, "media.name"); next }
        END { emit() }
    '
}

# Emit matching stream rows as "sink-input-id mute-state". Usually
# application.name/binary identifies Mopidy directly. If the stream uses a
# generic GStreamer name, inspect only its owning PID as a fallback.
mopidy_pulse_matching_inputs() {
    local records id muted app binary pid media_name cmd app_l binary_l media_l cmd_l matched
    records="$(mopidy_pulse_parse_sink_inputs)" || return 1
    [[ -n "$records" ]] || return 1
    while IFS=$'\034' read -r id muted app binary pid media_name; do
        [[ "$id" =~ ^[0-9]+$ ]] || continue
        app_l="${app,,}"
        binary_l="${binary,,}"
        media_l="${media_name,,}"
        matched=0
        if [[ "$app_l" == *mopidy* || "$binary_l" == *mopidy* || "$media_l" == *mopidy* ]]; then
            matched=1
        elif [[ "$pid" =~ ^[0-9]+$ ]]; then
            # application.process.binary can be a generic Python/GStreamer
            # executable; consult the owning PID when identifying metadata is
            # absent or generic. Empty pactl properties must not shift the PID.
            cmd="$(ps -p "$pid" -o args= 2>/dev/null || true)"
            cmd_l="${cmd,,}"
            [[ "$cmd_l" == *mopidy* ]] && matched=1
        fi
        if (( matched )); then
            [[ "$muted" == "yes" ]] || muted=no
            printf '%s %s\n' "$id" "$muted"
        fi
    done <<< "$records"
}

# Print true/false when a Mopidy sink input is available; fail when the stream
# cannot be identified, allowing mixer.sh to use its Mopidy RPC fallback.
mopidy_pulse_get_mute() {
    local inputs id muted found=0 all_muted=1
    inputs="$(mopidy_pulse_matching_inputs)" || return 1
    [[ -n "$inputs" ]] || return 1
    while read -r id muted; do
        [[ "$id" =~ ^[0-9]+$ ]] || continue
        found=1
        [[ "$muted" == "yes" ]] || all_muted=0
    done <<< "$inputs"
    (( found )) || return 1
    if (( all_muted )); then printf 'true\n'; else printf 'false\n'; fi
}

mopidy_pulse_set_mute() {
    local target="${1:-}" inputs id muted found=0
    [[ "$target" == "true" || "$target" == "false" ]] || return 2
    command -v pactl >/dev/null 2>&1 || return 1
    inputs="$(mopidy_pulse_matching_inputs)" || return 1
    [[ -n "$inputs" ]] || return 1
    local pactl_target=0
    [[ "$target" == "true" ]] && pactl_target=1
    while read -r id muted; do
        [[ "$id" =~ ^[0-9]+$ ]] || continue
        pactl set-sink-input-mute "$id" "$pactl_target" >/dev/null 2>&1 || return 1
        found=1
    done <<< "$inputs"
    (( found ))
}
