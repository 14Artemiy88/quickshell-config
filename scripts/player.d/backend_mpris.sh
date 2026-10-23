#!/bin/bash

# Cache the playerctl inventory for this one Player-script invocation. The
# process is short-lived and metadata polling starts a fresh script each time,
# so this cache avoids duplicate `playerctl -l` launches without keeping stale
# player presence across UI refreshes.
declare -ag PLAYERCTL_ACTIVE_PLAYERS_CACHE=()
declare -g PLAYERCTL_ACTIVE_PLAYERS_CACHE_LOADED=0
# The Player dispatcher preflights browser metadata to give an active Jitsi/Talk
# call priority over paused desktop players. Reuse that exact response if the
# normal backend loop reaches the browser later in the same invocation.
declare -g PLAYERCTL_PREFETCHED_PLAYER=""
declare -g PLAYERCTL_PREFETCHED_METADATA=""

load_playerctl_active_players() {
    [[ "$PLAYERCTL_ACTIVE_PLAYERS_CACHE_LOADED" == "1" ]] && return 0
    PLAYERCTL_ACTIVE_PLAYERS_CACHE_LOADED=1
    PLAYERCTL_ACTIVE_PLAYERS_CACHE=()

    local listing=""
    listing=$(playerctl -l 2>/dev/null) || listing=""
    if [[ -n "$listing" ]]; then
        mapfile -t PLAYERCTL_ACTIVE_PLAYERS_CACHE <<< "$listing"
    fi
}

mpris_player_is_active() {
    local player="${1:-}" candidate
    [[ -n "$player" ]] || return 1
    load_playerctl_active_players
    for candidate in "${PLAYERCTL_ACTIVE_PLAYERS_CACHE[@]}"; do
        [[ "$candidate" == "$player" ]] && return 0
    done
    return 1
}

get_mpris_player_metadata() {
    local player="$1"
    local image="$DEFAULT_IMG"
    local service="$DEFAULT_TEXT"
    # Use a single-byte delimiter: Bash splits IFS bytewise, so a multi-byte
    # Unicode separator can collide with UTF-8 bytes inside titles/artists.
    local s=$'\x1f'
    local params='{{status}}'"${s}"'{{title}}'"${s}"'{{artist}}'"${s}"'{{position}}'"${s}"'{{mpris:length}}'"${s}"'-{{duration(mpris:length - position)}}'"${s}"'{{mpris:artUrl}}'"${s}"'{{xesam:url}}'
    local metadata status title artist position len timeleft img url

    [[ -n "$player" ]] || return
    mpris_player_is_active "$player" || return

    if [[ "${PLAYERCTL_PREFETCHED_PLAYER:-}" == "$player" ]]; then
        metadata="${PLAYERCTL_PREFETCHED_METADATA:-}"
        # Consume once. If this response is incomplete during a track/service
        # transition, a later fallback attempt can perform a fresh query.
        PLAYERCTL_PREFETCHED_PLAYER=""
        PLAYERCTL_PREFETCHED_METADATA=""
    else
        metadata=$(playerctl -p "$player" metadata -f "$params" 2>/dev/null)
    fi
    [[ -z "$metadata" ]] && return

    # Parse fields from the complete metadata string rather than using `read`.
    # `read` stops at an embedded newline, which can truncate a title/artist
    # and shift every following field. Parameter expansion preserves embedded
    # newlines while splitting only on our single-byte separator.
    local remaining_metadata="$metadata"
    local -a metadata_fields=()
    while [[ "$remaining_metadata" == *"$s"* ]]; do
        metadata_fields+=("${remaining_metadata%%"$s"*}")
        remaining_metadata="${remaining_metadata#*"$s"}"
    done
    metadata_fields+=("$remaining_metadata")
    [[ ${#metadata_fields[@]} -eq 8 ]] || return
    status="${metadata_fields[0]}"
    title="${metadata_fields[1]}"
    artist="${metadata_fields[2]}"
    position="${metadata_fields[3]}"
    len="${metadata_fields[4]}"
    timeleft="${metadata_fields[5]}"
    img="${metadata_fields[6]}"
    url="${metadata_fields[7]}"

    # A registered MPRIS service may be stopped or temporarily expose stale,
    # incomplete metadata while switching tracks. Such a response must not
    # claim the PlayerWidget and prevent the next configured backend from
    # being queried.
    [[ "$status" == "Playing" || "$status" == "Paused" ]] || return
    # Some browser integrations expose the Talk URL while returning an empty
    # title; let the site-specific fallback below recover the room name rather
    # than abandoning this backend and emitting the global "silence" payload.
    local is_talk_url=false
    if [[ "$player" == "plasma-browser-integration" && "$url" == *"talk.sima-team.ru"* ]]; then
        is_talk_url=true
    fi
    if [[ -z "${title//[[:space:]]/}" || "$title" == "null" ]]; then
        [[ "$is_talk_url" == true ]] || return
        title=""
    fi

    local numeric_re='^[0-9]+([.][0-9]+)?$'
    if [[ -n "$position" && "$position" != "null" && ! "$position" =~ $numeric_re ]]; then
        return
    fi
    if [[ "$position" == "null" ]]; then position=""; fi
    if [[ "$len" == "null" ]]; then len=""; fi
    if [[ -n "$len" && ! "$len" =~ $numeric_re ]]; then return; fi

    [[ "$player" == "org.telegram.desktop" && "$status" != "Playing" ]] && return

    # KDE's browser MPRIS integration reports Talk/Jitsi rooms with a generic
    # suffix (for example "Teamf | Talk" or "Teamf | Jitsi Meet"). The Player's
    # centered no-art fallback uses the `text` field, so keep that field
    # meaningful for active calls instead of showing "silence"/"no image".
    # Restrict the override to the Talk host or an explicit Talk/Jitsi suffix
    # so ordinary browser media keeps its existing display behavior.
    if [[ "$player" == "plasma-browser-integration" ]] && \
       { [[ "$url" == *"talk.sima-team.ru"* ]] || [[ "$title" == *" | Talk" ]] || [[ "$title" == *" | Jitsi Meet" ]]; }; then
        # Support both suffixes because different browser builds report the
        # same Talk room as either "Room | Talk" or "Room | Jitsi Meet".
        title="${title% | Talk}"
        title="${title% | Jitsi Meet}"
        # Browser metadata may expose a generic label rather than the room
        # name. In that case, recover the room from the URL path.
        if [[ -z "${title//[[:space:]]/}" || "${title,,}" == "null" || "${title,,}" == "talk" || "${title,,}" == "jitsi meet" || "${title,,}" == "silence" || "${title,,}" == "no image" ]]; then
            local url_path="${url#*://}"
            if [[ "$url_path" == */* ]]; then
                url_path="${url_path#*/}"
            else
                url_path=""
            fi
            url_path="${url_path%%[?#]*}"
            url_path="${url_path%/}"
            if [[ -n "$url_path" ]]; then
                title="${url_path##*/}"
            else
                title="talk"
            fi
        fi
        service="$title"
    fi

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
            image=$(get_image "$img" "$player")
            ;;
    esac

    # get_json serializes all string fields through jq --arg. Keep the original
    # title intact here: manual escaping would alter backslashes and make quotes
    # appear with an extra slash in the displayed metadata.

    # Emit progress only if both position and duration are usable numeric
    # values. Metadata-only/live items remain displayable without a fake 0%.
    # Duration is reported in microseconds and is already validated as a
    # decimal string above. Check for any non-zero digit using Bash built-ins
    # instead of spawning awk on every successful MPRIS poll.
    local duration_nonzero="${len//./}"
    duration_nonzero="${duration_nonzero//0/}"
    if [[ "$position" =~ $numeric_re && "$len" =~ $numeric_re && -n "$duration_nonzero" ]]; then
        get_json \
            --first_line "$title" \
            --second_line "$artist" \
            --timeleft "$timeleft" \
            --pos_ms "$position" \
            --dur_ms "$len" \
            --status "${icons[$status]:-}" \
            --image "$image" \
            --artist "$service" \
            --player "$player"
    else
        get_json \
            --first_line "$title" \
            --second_line "$artist" \
            --timeleft "$timeleft" \
            --status "${icons[$status]:-}" \
            --image "$image" \
            --artist "$service" \
            --player "$player"
    fi
}


# Получение метаданных DeadBeeF
