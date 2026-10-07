#!/bin/bash

PLAYER_SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$PLAYER_SCRIPT_DIR/common.sh"
source "$PLAYER_SCRIPT_DIR/backend_mopidy.sh"

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

# Функция для создания изображения
create_image() {
    local title="$1"
    local path="$2"
    local position="$3"
    local image_path="$IMG_PATH/$title$IMG_SUFFIX"

    rm -f "$image_path" 2>/dev/null
    ffmpeg -ss "$position" -i "$path" -vframes 1 -y "$image_path" 2>/dev/null
}

# Основная функция паузы
pause() {
    case "$1" in
        mopidy)
            mopidy_pause_toggle
            ;;
        mpv)
            # Получаем все необходимые свойства за один вызов
            mapfile -t props < <(get_mpv_properties "media-title" "path" "time-pos")
            [[ ${#props[@]} -lt 3 ]] && exit 0

            title="${props[0]//\"/}"
            path="${props[1]//\"/}"
            position="${props[2]%%.*}"

            create_image "$title" "$path" "$position"
            eval "${PLAYER_COMMANDS[mpv]}"
            ;;
        *)
            eval "$(printf "${PLAYER_COMMANDS[$1]}" "$1")"
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
        title="${props[1]//\"/}"
        path="${props[2]//\"/}"

        pos_seconds=$(awk -v p="$pos_percent" -v d="$duration" 'BEGIN {print d * p / 100}')
        create_image "$title" "$path" "$pos_seconds"

        echo "{ \"command\": [\"set_property\", \"time-pos\", $pos_seconds] }" | \
            socat - "$MPV_SOCKET" >/dev/null
        exit 0
    fi

    # MPRIS-плееры: всегда адресуем именно тот backend, который сейчас
    # выбран PlayerWidget. Никакого fallback на другой MPRIS-плеер.
    if [[ -n "$player_name" ]] && command -v playerctl >/dev/null 2>&1; then
        normalize_player_name() {
            local value="$1"
            value="${value#org.mpris.MediaPlayer2.}"
            value="${value#org.mpris.MediaPlayer2.}"
            value="${value//[^[:alnum:]]/}"
            printf '%s' "${value,,}"
        }

        mpris_player=""
        wanted_norm=$(normalize_player_name "$player_name")
        while IFS= read -r candidate; do
            [[ -z "$candidate" ]] && continue
            candidate_norm=$(normalize_player_name "$candidate")
            if [[ "$candidate_norm" == "$wanted_norm" ]]; then
                mpris_player="$candidate"
                break
            fi
        done < <(playerctl -l 2>/dev/null || true)

        # Известные варианты имён DeaDBeeF/Spotify.
        if [[ -z "$mpris_player" ]]; then
            case "${player_name,,}" in
                deadbeef|deadbeef-player)
                    for candidate in "DeaDBeeF" "deadbeef" "org.mpris.MediaPlayer2.DeaDBeeF" "org.mpris.MediaPlayer2.deadbeef"; do
                        if playerctl -p "$candidate" status >/dev/null 2>&1; then
                            mpris_player="$candidate"
                            break
                        fi
                    done
                    ;;
                spotify|spotify-client)
                    for candidate in "spotify" "Spotify" "org.mpris.MediaPlayer2.spotify"; do
                        if playerctl -p "$candidate" status >/dev/null 2>&1; then
                            mpris_player="$candidate"
                            break
                        fi
                    done
                    ;;
            esac
        fi

        if [[ -n "$mpris_player" ]]; then
            length_us=$(playerctl -p "$mpris_player" metadata mpris:length 2>/dev/null || true)
            if [[ ! "$length_us" =~ ^[0-9]+$ ]] || (( length_us <= 0 )); then
                length_us=""
            fi

            # Если MPRIS length недоступен (например, у конкретного backend),
            # используем длительность, которую Player уже получил от своего
            # собственного backend.
            if [[ -z "$length_us" && "$duration_ms" =~ ^[0-9]+$ ]] && (( duration_ms > 0 )); then
                length_us=$((duration_ms * 1000))
            fi

            if [[ "$length_us" =~ ^[0-9]+$ ]] && (( length_us > 0 )); then
                target_seconds=$(awk -v p="$pos_percent" -v l="$length_us" 'BEGIN {printf "%.6f", (p * l) / 100000000}')

                if playerctl -p "$mpris_player" position "$target_seconds" >/dev/null 2>&1; then
                    exit 0
                fi

                # Fallback: относительный Seek. Берём текущую позицию самой
                # командой playerctl, а не mpris:position metadata.
                current_seconds=$(playerctl -p "$mpris_player" position 2>/dev/null || true)
                if [[ "$current_seconds" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
                    delta_seconds=$(awk -v target="$target_seconds" -v current="$current_seconds" 'BEGIN { printf "%.3f", target - current }')
                    if ! awk -v d="$delta_seconds" 'BEGIN { exit !(d > -0.005 && d < 0.005) }'; then
                        if [[ "$delta_seconds" == -* ]]; then
                            seek_value="${delta_seconds#-}-"
                        else
                            seek_value="${delta_seconds}+"
                        fi
                        if playerctl -p "$mpris_player" position "$seek_value" >/dev/null 2>&1; then
                            exit 0
                        fi
                    else
                        exit 0
                    fi
                fi
            fi
        fi

        # ВАЖНО: когда Player явно передал backend, не трогаем другой MPRIS
        # player только потому, что выбранный backend не поддержал seek.
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
