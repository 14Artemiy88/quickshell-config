#!/bin/bash
# Shared Player backend helpers.
PLAYER_LIB_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$PLAYER_LIB_DIR/../env"

declare -r IMG_PATH="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/desktop-shell-player"
declare -r IMG_SUFFIX=".png"
declare -r DEFAULT_IMG="$QS_CONFIG_DIR/assets/1px.png"
declare -r DEFAULT_TEXT="no image"
declare -r DEFAULT_TITLE_CLASS="default"

declare -A icons=(
    ["Playing"]="" ["playing"]=""
    ["Paused"]=""  ["paused"]=""
)

declare -A cover_cache



find_cover() {
    local album_dir="$1" parent_dir="${1%/*}" art found
    local -a names=(cover folder artwork front albumart album image logo)
    local -a exts=(jpg jpeg png bmp)

    # Проверка в текущем и родительском каталоге
    for dir in "$album_dir" "$parent_dir"; do
        for name in "${names[@]}"; do
            for ext in "${exts[@]}"; do
                art="$dir/$name.$ext"
                [[ -f "$art" ]] && { printf '%s\n' "$art"; return 0; }
            done
        done
    done

    # Fallback: find один раз для обоих каталогов
    found=$(find "$album_dir" "$parent_dir" -maxdepth 2 -type f \( \
        -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.bmp" \) \
        -print -quit 2>/dev/null)

    [[ -n "$found" ]] && { printf '%s\n' "$found"; return 0; }
    return 1
}

escape_path() {
    local p="$1"
    p="${p//\\/\\}"
    p="${p//\'/\\\'}"
    printf '%s\n' "${p//\"/\\\"}"
}

# Основная функция
get_album_img() {
    local file="$1"
    local album_dir="${file%/*}"

    # Используем кэшированное значение если доступно
    if [[ -v cover_cache["$album_dir"] ]]; then
        echo "${cover_cache["$album_dir"]}"
        return
    fi

    # Для нелокальных треков - дефолтная обложка
    if [[ ! -f "$file" ]]; then
        local default_escaped
        default_escaped=$(escape_path "$DEFAULT_IMG")
        cover_cache["$album_dir"]="$default_escaped"
        echo "$default_escaped"
        return
    fi

    # Ищем обложку
    local art
    art=$(find_cover "$album_dir")

    # Кэшируем результат
    if [[ -f "$art" ]]; then
        local art_escaped
        art_escaped=$(escape_path "$art")
        cover_cache["$album_dir"]="$art_escaped"
        echo "$art_escaped"
    else
        local default_escaped
        default_escaped=$(escape_path "$DEFAULT_IMG")
        cover_cache["$album_dir"]="$default_escaped"
        echo "$default_escaped"
    fi
}

get_image() {
    local img_url="$1" image_path

    # Возвращаем дефолтное изображение, если URL пустой
    if [[ -z "$img_url" ]]; then
        img_url=$(playerctl metadata -f '{{ mpris:artUrl }}' 2>/dev/null)
        [[ -z "$img_url" ]] && { printf '%s\n' "$DEFAULT_IMG"; return; }
        printf '%s\n' "${img_url#file://}"
        return
    fi

    # Извлекаем имя файла из URL
    image_path="$IMG_PATH/${img_url##*/}"
    image_path="${image_path%.*}$IMG_SUFFIX"

    # Загружаем только если файл не существует
    if [[ ! -f "$image_path" ]]; then
        curl -s -o "$image_path" "$img_url" 2>/dev/null
        mogrify -format png "$image_path" 2>/dev/null
    fi

    printf '%s\n' "$image_path"
}

# Форматирование времени
timeFormat() {
    local milliseconds=$1
    local seconds=$((milliseconds / 1000))
    printf "%02d:%02d:%02d\n" $((seconds / 3600)) $(((seconds % 3600) / 60)) $((seconds % 60))
}

# Получение метаданных Mopidy
get_json() {
    # Параметры по умолчанию
    local first_line second_line third_line timeleft pos_ms dur_ms status image artist player title_class duration_ms

    title_class="$DEFAULT_TITLE_CLASS"
    # Парсинг аргументов
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --first_line) first_line="$2"; shift 2 ;;
            --second_line) second_line="$2"; shift 2 ;;
            --third_line) third_line="$2"; shift 2 ;;
            --timeleft) timeleft="$2"; shift 2 ;;
            --pos_ms) pos_ms="$2"; shift 2 ;;
            --dur_ms) dur_ms="$2"; duration_ms="$2"; shift 2 ;;
            --status) status="$2"; shift 2 ;;
            --image) image="$2"; shift 2 ;;
            --artist) artist="$2"; shift 2 ;;
            --player) player="$2"; shift 2 ;;
            --title_class) title_class="$2"; shift 2 ;;
            *) shift ;; # игнорируем неизвестные параметры
        esac
    done

    # Рассчет позиции в процентах
    local position_percent=0
    if [[ $dur_ms -gt 0 ]]; then
        position_percent=$(( (pos_ms * 100) / dur_ms ))
    fi

    # Безопасная генерация JSON с помощью jq
    jq -n \
        --arg first_line "$first_line" \
        --arg second_line "$second_line" \
        --arg third_line "$third_line" \
        --arg timeleft "$timeleft" \
        --arg position "$position_percent" \
        --arg status "$status" \
        --arg image "$image" \
        --arg text "$artist" \
        --arg player "$player" \
        --arg title_class "$title_class" \
        --arg duration "$duration_ms" \
        '{
            first_line: $first_line,
            second_line: $second_line,
            third_line: $third_line,
            timeleft: $timeleft,
            position: $position,
            status: $status,
            image: $image,
            text: $text,
            player: $player,
            title_class: $title_class,
            duration: $duration
        }'

    exit 0
}

