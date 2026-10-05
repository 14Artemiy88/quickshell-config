#!/bin/bash

get_mpv_player_metadata() {
    if ! pgrep -x mpv >/dev/null; then
        return
    fi

    local mpvsocket="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/mpvsocket"
    [[ ! -S "$mpvsocket" ]] && return

    local mpv_data title position duration path remaining timeleft
    
    mpv_data=$(socat - "$mpvsocket" <<< $'{"command": ["get_property_string", "media-title"], "request_id": 1}\n{"command": ["get_property", "time-pos"], "request_id": 2}\n{"command": ["get_property", "duration"], "request_id": 3}\n{"command": ["get_property", "path"], "request_id": 4}')

    title=$(jq -r 'select(.request_id == 1) | .data' <<< "$mpv_data")
    position=$(jq -r 'select(.request_id == 2) | .data' <<< "$mpv_data")
    duration=$(jq -r 'select(.request_id == 3) | .data' <<< "$mpv_data")
    path=$(jq -r 'select(.request_id == 4) | .data' <<< "$mpv_data")

    [[ -z "$position" || "$position" == "null" ]] && return

    # Рассчитываем оставшееся время
    remaining=$(awk -v d="$duration" -v p="$position" 'BEGIN {printf "%.0f", d - p}')
    timeleft=$(date -u -d @"$remaining" +'%H:%M:%S')
    timeleft=${timeleft##00:}

    title="${title//\"/}"

    # Генерируем путь к изображению
    local image_path="$IMG_PATH/${title}${IMG_SUFFIX}" ts

    # Создаем превью если файла нет или старше 60 секунд
    if [[ ! -f "$image_path" ]] || { read -r ts < <(stat -c %Y "$image_path" 2>/dev/null) && (( $(date +%s) - ts > 60 )); }; then
        ffmpeg -ss "$position" -i "$path" -vframes 1 -y "$image_path" 2>/dev/null
    fi
    [[ -f "$image_path" ]] || image_path="$DEFAULT_IMG"


    get_json \
        --first_line "$title" \
        --timeleft "$timeleft" \
        --pos_ms "${position%%.*}" \
        --dur_ms "${duration%%.*}" \
        --image "$image_path" \
        --artist "$DEFAULT_TEXT" \
        --player "mpv"
}

# Получение метаданных через playerctl
