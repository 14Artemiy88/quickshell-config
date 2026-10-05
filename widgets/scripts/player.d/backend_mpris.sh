#!/bin/bash

get_mpris_player_metadata() {
    local player="$1"
    local image="$DEFAULT_IMG"
    local service="$DEFAULT_TEXT"
    local s="␞"
    local params='{{status}}'"${s}"'{{title}}'"${s}"'{{artist}}'"${s}"'{{position}}'"${s}"'{{mpris:length}}'"${s}"'-{{duration(mpris:length - position)}}'"${s}"'{{mpris:artUrl}}'"${s}"'{{xesam:url}}'
    local metadata status title artist position len timeleft img url active_players

    [[ -n "$player" ]] || return
    active_players=$(playerctl -l 2>/dev/null || true)
    grep -Fxq "$player" <<< "$active_players" || return

    metadata=$(playerctl -p "$player" metadata -f "$params" 2>/dev/null)
    [[ -z "$metadata" ]] && return

    status="${metadata%%␞*}"
    metadata="${metadata#*␞}"

    [[ "$player" == "org.telegram.desktop" && "$status" != "Playing" ]] && return

    IFS="$s" read -r title artist position len timeleft img url <<< "$metadata"

    case "$title" in
        *"Кинопоиск"*) service="kinopoisk"; title=${title/" — смотреть онлайн в хорошем качестве — Кинопоиск"/} ;;
        *"Twitch"*)    service="twitch";    title=${title/" - Twitch"/}; service=$title; ;;
        *"VK"*)        service="vk";        title=${title/"VK Видео — смотрѣть безплатно"/} ;;
        *"Телемост"*)
            get_json \
                --image "$DEFAULT_IMG" \
                --artist "telemost" \
                --player "$player"
            return ;;
    esac

    case "$url" in
        *"youtube.com/"*|*"youtu.be/"*|*"googlevideo.com/"*|*"soundcloud.com/"*|*"spotify.com/"*)
            service="${artist:-youtube}"
            ;;
        *)
            image=$(get_image "$img")
            ;;
    esac

    # Экранирование спецсимволов
    title=${title//\\/|}
    title=${title//\"/\\\"}

    # Формируем JSON
    if [[ -n "$position" ]]; then
        get_json \
            --first_line "$title" \
            --second_line "$artist" \
            --timeleft "$timeleft" \
            --pos_ms "$position" \
            --dur_ms "$len" \
            --status "${icons[$status]}" \
            --image "$image" \
            --artist "$service" \
            --player "$player"
    else
        get_json \
            --first_line "$title" \
            --timeleft "$timeleft" \
            --image "$image" \
            --artist "$service" \
            --player "$player"
    fi
}


# Получение метаданных DeadBeeF
