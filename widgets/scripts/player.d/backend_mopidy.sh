#!/bin/bash

get_mopidy_player_metadata() {
    if ! pgrep -x mopidy >/dev/null; then
        return
    fi

    local status_json rpc_data current trackTime current_album current_album_date current_artist current_length current_title
    local format_album time_left cls

    # Проверяем статус воспроизведения
    status_json=$(curl -s -H 'Content-Type: application/json' -d '{"jsonrpc": "2.0", "id": 1, "method": "core.playback.get_state"}' http://localhost:6680/mopidy/rpc)
    [[ "$status_json" != *'"result":"playing"'* ]] && return

    # Получаем данные за один запрос
    rpc_data=$(curl -s -H 'Content-Type: application/json' -d '[
        {"jsonrpc": "2.0", "id": 1, "method": "core.playback.get_current_tl_track"},
        {"jsonrpc": "2.0", "id": 2, "method": "core.playback.get_time_position"}
    ]' http://localhost:6680/mopidy/rpc)

    current=$(jq -r '.[0].result' <<< "$rpc_data")
    trackTime=$(jq -r '.[1].result' <<< "$rpc_data")

    # Извлекаем метаданные
    current_album=$(jq -r '.track.album.name' <<< "$current")
    current_album_date=$(jq -r '.track.album.date' <<< "$current")
    current_artist=$(jq -r '.track.artists[0].name' <<< "$current")
    current_length=$(jq -r '.track.length' <<< "$current")
    current_title=$(jq -r '.track.name' <<< "$current")

    # Форматируем информацию об альбоме
    format_album="$current_album_date"
    [[ -n "$current_album" ]] && format_album+=" - $current_album"
    [[ "$current_album_date" == "null" && "$current_album" == "null" ]] && format_album=""
    [[ "$current_artist" == "null" ]] && current_artist="music"

    # Рассчитываем оставшееся время
    time_left=$(timeFormat $((current_length - trackTime)))
    time_left=${time_left##00:}

    # Определяем класс для заголовка
    cls=$DEFAULT_TITLE_CLASS
    [[ ${#current_title} -gt 10 ]] && cls="more_ten"

    # Формируем JSON
    get_json \
        --first_line "$current_title" \
        --second_line "$format_album" \
        --timeleft "$time_left" \
        --pos_ms "$trackTime" \
        --dur_ms "$current_length" \
        --status "${icons[playing]}" \
        --image "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/album_cover.png" \
        --artist "$current_artist" \
        --player "mopidy" \
        --title_class "$cls"
}

# Получение метаданных MPV
