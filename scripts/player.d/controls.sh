#!/bin/bash

PLAYER_SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$PLAYER_SCRIPT_DIR/common.sh"
source "$PLAYER_SCRIPT_DIR/../mopidy/player_backend.sh"

declare -r MPV_SOCKET="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/mpvsocket"
declare -A PLAYER_COMMANDS=(
    ["mpv"]='echo "{ \"command\": [\"cycle\", \"pause\"] }" | socat - "$MPV_SOCKET"'
    ["org.telegram.desktop"]="playerctl -p \"%s\" play-pause"
    ["plasma-browser-integration"]="playerctl -p %s play-pause"
    ["spotify"]="playerctl -p %s play-pause"
    ['deadbeef']="deadbeef --toggle-pause"
)

# Функция для получения свойств MPV за один вызов
get_mpv_properties() {
    local properties=("${@}")
    local commands=()
    for prop in "${properties[@]}"; do
        commands+=('{ "command": ["get_property", "'"$prop"'"] }')
    done
    printf "%s\n" "${commands[@]}" | socat - "$MPV_SOCKET" | jq -r '.data'
}

# Capture a fresh mpv frame on pause/seek. Uses the same source-keyed cache
# as the metadata backend, but forces a new versioned image so the player view
# changes immediately instead of reusing QtQuick's cached URL.
create_image() {
    local title="$1"
    local path="$2"
    local position="$3"
    local image_path=""

    image_path=$(get_mpv_snapshot "$path" "$position" true 0) || image_path=""
    [[ -n "$image_path" && -s "$image_path" ]]
}

# Основная функция паузы
pause() {
    # Backend IDs normally arrive lowercase from Player.qml, but normalize here
    # as well so a backend-name casing change cannot silently disable playback.
    local backend="${1,,}"
    case "$backend" in
        mopidy)
            mopidy_pause_toggle
            ;;
        mpv)
            # Получаем все необходимые свойства за один вызов
            mapfile -t props < <(get_mpv_properties "media-title" "path" "time-pos")
            [[ ${#props[@]} -lt 3 ]] && exit 0

            title="${props[0]}"
            path="${props[1]}"
            position="${props[2]%%.*}"

            create_image "$title" "$path" "$position"
            eval "${PLAYER_COMMANDS[mpv]}"
            ;;
        *)
            local command_template="${PLAYER_COMMANDS[$backend]:-}"
            if [[ -n "$command_template" ]]; then
                eval "$(printf "$command_template" "$backend")"
            fi
            ;;
    esac
    exit 0
}

# Основная функция следующего трека
next() {
    if [[ "$1" == "mopidy" ]]; then
        mopidy_next
    else
        playerctl -p "$1" next
    fi
    exit 0
}

# Основная функция предыдущего трека
prev() {
    if [[ "$1" == "mopidy" ]]; then
        mopidy_prev
    else
        playerctl -p "$1" prev
    fi
    exit 0
}


# Функция установки позиции
position() {
    local pos_percent="$1"
    local player_name="${2:-}"
    local duration_ms="${3:-}"

    if [[ "$player_name" == "mopidy" ]]; then
        mopidy_seek_percent "$pos_percent" "$duration_ms"
        exit 0
    fi

    # MPV использует собственный IPC и обрабатывается только когда именно
    # mpv является активным player backend.
    if [[ "$player_name" == "mpv" && -S "$MPV_SOCKET" ]]; then
        mapfile -t props < <(get_mpv_properties "duration" "media-title" "path")
        [[ ${#props[@]} -lt 3 ]] && exit 0

        duration="${props[0]//\"/}"
        title="${props[1]}"
        path="${props[2]}"

        pos_seconds=$(awk -v p="$pos_percent" -v d="$duration" 'BEGIN {print d * p / 100}')
        create_image "$title" "$path" "$pos_seconds"

        echo "{ \"command\": [\"set_property\", \"time-pos\", $pos_seconds] }" | \
            socat - "$MPV_SOCKET" >/dev/null
        exit 0
    fi

    # DeaDBeeF's MPRIS service uses the canonical, case-sensitive bus name
    # org.mpris.MediaPlayer2.DeaDBeeF. The metadata backend intentionally keeps
    # the app's normalized internal ID ("deadbeef"), so route it to the actual
    # MPRIS identity here.
    # DeaDBeeF metadata is read through its CLI, where duration is milliseconds;
    # MPRIS position commands use seconds. Convert that fallback explicitly.
    if [[ "$player_name" == "deadbeef" ]]; then
        if ! command -v playerctl >/dev/null 2>&1; then
            exit 0
        fi

        local deadbeef_mpris_player="DeaDBeeF"
        local deadbeef_length_us="" deadbeef_target_seconds=""
        deadbeef_length_us=$(playerctl -p "$deadbeef_mpris_player" metadata mpris:length 2>/dev/null || true)

        if [[ "$deadbeef_length_us" =~ ^[0-9]+$ ]] && (( deadbeef_length_us > 0 )); then
            deadbeef_target_seconds=$(awk -v p="$pos_percent" -v l="$deadbeef_length_us" 'BEGIN {printf "%.6f", (p * l) / 100000000}')
        elif [[ "$duration_ms" =~ ^[0-9]+([.][0-9]+)?$ ]] && \
             awk -v d="$duration_ms" 'BEGIN {exit !(d > 0)}'; then
            deadbeef_target_seconds=$(awk -v p="$pos_percent" -v d="$duration_ms" 'BEGIN {printf "%.6f", (p * d) / 100000}')
        else
            exit 0
        fi

        # playerctl sends MPRIS SetPosition with DeaDBeeF's current track ID.
        # This avoids targeting a non-existent lowercase MPRIS player alias.
        playerctl -p "$deadbeef_mpris_player" position "$deadbeef_target_seconds" >/dev/null 2>&1 || true
        exit 0
    fi

    # MPRIS-плееры: Player передаёт точный backend ID, который только что
    # использовался для чтения metadata. Не выполняем повторный discovery через
    # playerctl -l: он может вернуть несколько alias-вариантов одного сервиса.
    if [[ -n "$player_name" ]] && command -v playerctl >/dev/null 2>&1; then
        local length_us target_seconds current_seconds delta_seconds seek_value
        length_us=$(playerctl -p "$player_name" metadata mpris:length 2>/dev/null || true)
        if [[ ! "$length_us" =~ ^[0-9]+$ ]] || (( length_us <= 0 )); then
            # The MPRIS backend stores mpris:length in root.player.duration
            # in microseconds. Preserve that unit rather than multiplying by
            # 1000, which would place the target far beyond the track.
            if [[ "$duration_ms" =~ ^[0-9]+$ ]] && (( duration_ms > 0 )); then
                length_us="$duration_ms"
            else
                exit 0
            fi
        fi

        target_seconds=$(awk -v p="$pos_percent" -v l="$length_us" 'BEGIN {printf "%.6f", (p * l) / 100000000}')

        # A bare playerctl position argument sets an absolute position in
        # seconds; +/- suffixes are reserved for relative seeks.
        if playerctl -p "$player_name" position "$target_seconds" >/dev/null 2>&1; then
            exit 0
        fi

        # Fallback for players that reject absolute position commands but
        # implement MPRIS Seek: calculate a relative offset from fresh position.
        current_seconds=$(playerctl -p "$player_name" position 2>/dev/null || true)
        if [[ "$current_seconds" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
            delta_seconds=$(awk -v target="$target_seconds" -v current="$current_seconds" 'BEGIN { printf "%.3f", target - current }')
            if ! awk -v d="$delta_seconds" 'BEGIN { exit !(d > -0.005 && d < 0.005) }'; then
                if [[ "$delta_seconds" == -* ]]; then
                    seek_value="${delta_seconds#-}-"
                else
                    seek_value="${delta_seconds}+"
                fi
                playerctl -p "$player_name" position "$seek_value" >/dev/null 2>&1 || true
            fi
        fi
        exit 0
    fi

    # Совместимость со старыми вызовами без имени player.
    length=$(playerctl -p plasma-browser-integration metadata -f '{{ mpris:length }}' 2>/dev/null)
    if [[ -n "$length" ]]; then
        position=$((pos_percent * length / 100000000))
        playerctl -p plasma-browser-integration position "$position" >/dev/null 2>&1
    fi
    exit 0
}

# Главная логика
case "$1" in
    pause) pause "$2" ;;
    position) position "$2" "$3" "$4" ;;
    next) next "$2" ;;
    prev) prev "$2" ;;
esac
