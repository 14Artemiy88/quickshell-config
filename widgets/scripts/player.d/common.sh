#!/bin/bash
# Shared Player backend helpers.
PLAYER_LIB_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$PLAYER_LIB_DIR/../env"

declare -r IMG_PATH="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/desktop-shell-player"
declare -r IMG_SUFFIX=".png"
declare -r DEFAULT_IMG="$QS_PROJECT_DIR/assets/1px.png"
declare -r DEFAULT_TEXT="no image"
declare -r DEFAULT_TITLE_CLASS="default"

declare -A icons=(
    ["Playing"]="" ["playing"]=""
    ["Paused"]=""  ["paused"]=""
)

declare -A cover_cache

# mpv frame snapshots use source-keyed, versioned filenames. A unique filename
# for every successful capture is important because QtQuick.Image may cache a
# local image by URL and otherwise keep showing an old frame after its file is
# overwritten. Only a small time window of snapshots is retained per source.
mpv_snapshot_key() {
    local source_path="${1:-}"
    [[ -n "$source_path" ]] || return 1
    printf '%s' "$source_path" | sha256sum | awk '{print substr($1, 1, 24)}'
}

mpv_latest_snapshot_for_key() {
    local key="${1:-}" latest=""
    [[ -n "$key" && -d "$IMG_PATH" ]] || return 1
    latest=$(find "$IMG_PATH" -maxdepth 1 -type f -name "mpv-${key}-*.png" \
        -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -n 1) || true
    [[ -n "$latest" ]] || return 1
    printf '%s\n' "${latest#* }"
}

create_mpv_snapshot() {
    local source_path="${1:-}" position="${2:-}" key stamp temp_path final_path
    [[ -n "$source_path" && "$position" =~ ^[0-9]+([.][0-9]+)?$ ]] || return 1
    command -v ffmpeg >/dev/null 2>&1 || return 1
    command -v timeout >/dev/null 2>&1 || return 1
    mkdir -p "$IMG_PATH" 2>/dev/null || return 1

    key=$(mpv_snapshot_key "$source_path") || return 1
    stamp=$(date +%s%N 2>/dev/null)
    [[ "$stamp" =~ ^[0-9]+$ ]] || stamp="$(date +%s)-$$-$RANDOM"
    # Keep .png as the final suffix so ffmpeg can reliably infer the encoder.
    temp_path="$IMG_PATH/.mpv-${key}-${stamp}.tmp.png"
    final_path="$IMG_PATH/mpv-${key}-${stamp}.png"

    # Decode at most 15s and publish atomically: a failed/partial capture must
    # never replace the last known-good frame.
    if timeout 15s ffmpeg -nostdin -hide_banner -loglevel error \
        -ss "$position" -i "$source_path" -frames:v 1 -y "$temp_path" \
        </dev/null >/dev/null 2>&1 && [[ -s "$temp_path" ]]; then
        if mv -f -- "$temp_path" "$final_path"; then
            # Keep enough recent snapshots for asynchronous QML reads while
            # preventing an indefinitely growing cache during long playback.
            find "$IMG_PATH" -maxdepth 1 -type f \
                -name "mpv-${key}-*.png" -mmin +10 -delete 2>/dev/null || true
            printf '%s\n' "$final_path"
            return 0
        fi
    fi

    rm -f -- "$temp_path" 2>/dev/null || true
    return 1
}

get_mpv_snapshot() {
    local source_path="${1:-}" position="${2:-}" force="${3:-false}" ttl="${4:-60}"
    local key latest="" modified now captured="" attempt_path attempt_modified
    [[ -n "$source_path" && "$position" =~ ^[0-9]+([.][0-9]+)?$ ]] || return 1
    key=$(mpv_snapshot_key "$source_path") || return 1
    latest=$(mpv_latest_snapshot_for_key "$key") || latest=""
    attempt_path="$IMG_PATH/.mpv-${key}.attempt"

    if [[ "$force" != "true" ]]; then
        if [[ -n "$latest" && -s "$latest" ]]; then
            modified=$(stat -c %Y -- "$latest" 2>/dev/null || printf '0')
            now=$(date +%s)
            if [[ "$modified" =~ ^[0-9]+$ ]] && (( now - modified < ttl )); then
                printf '%s\n' "$latest"
                return 0
            fi
        fi

        # Avoid launching a potentially expensive ffmpeg process on every UI
        # poll when a source cannot be decoded. A failed attempt is retried
        # after the same interval as a normal frame refresh.
        if [[ -f "$attempt_path" ]]; then
            attempt_modified=$(stat -c %Y -- "$attempt_path" 2>/dev/null || printf '0')
            now=$(date +%s)
            if [[ "$attempt_modified" =~ ^[0-9]+$ ]] && (( now - attempt_modified < ttl )); then
                if [[ -n "$latest" && -s "$latest" ]]; then
                    printf '%s\n' "$latest"
                    return 0
                fi
                return 1
            fi
        fi
    fi

    captured=$(create_mpv_snapshot "$source_path" "$position") || captured=""
    if [[ -n "$captured" && -s "$captured" ]]; then
        rm -f -- "$attempt_path" 2>/dev/null || true
        printf '%s\n' "$captured"
        return 0
    fi

    # Record failures too, so a broken/unsupported stream is not retried on
    # every metadata-poll cycle. This marker is separate from snapshot mtime.
    mkdir -p "$IMG_PATH" 2>/dev/null || true
    date +%s > "$attempt_path" 2>/dev/null || true

    # If ffmpeg temporarily fails (unsupported stream, transient network issue,
    # etc.), keep the last valid frame instead of returning a broken file path.
    if [[ -n "$latest" && -s "$latest" ]]; then
        printf '%s\n' "$latest"
        return 0
    fi
    return 1
}
_find_cover_in_dir() {
    # Search a single directory only; never recurse into other albums.
    local dir="$1" art found name ext
    local -a names=(cover folder artwork front albumart album image logo)
    local -a exts=(jpg jpeg png bmp webp gif avif)

    [[ -d "$dir" ]] || return 1

    # Prefer conventional cover names over arbitrary images.
    for name in "${names[@]}"; do
        for ext in "${exts[@]}"; do
            art="$dir/$name.$ext"
            [[ -f "$art" ]] && { printf '%s\n' "$art"; return 0; }
        done
    done

    # Legacy fallback for arbitrary image names, directly in this directory.
    found=$(find "$dir" -maxdepth 1 -type f \
        \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \
           -o -iname "*.bmp" -o -iname "*.webp" -o -iname "*.gif" -o -iname "*.avif" \) \
        -print -quit 2>/dev/null)

    [[ -n "$found" ]] && { printf '%s\n' "$found"; return 0; }
    return 1
}

find_cover() {
    # Search the track directory first. If the track is inside a conventional
    # multi-disc folder (CD1, CD 2, Disc-1, Disk 2, etc.), also check exactly
    # one level up for the album cover stored beside CD1/CD2. This intentionally
    # avoids climbing through arbitrary folders where another album's art may
    # be found before the current album's artwork.
    local album_dir="$1" found dir_name parent
    local disc_dir_re='^[cC][dD]([ ._-]*[0-9]+)?$|^[dD][iI][sS][cC][ ._-]*[0-9]+$|^[dD][iI][sS][kK][ ._-]*[0-9]+$'
    [[ -d "$album_dir" ]] || return 1

    found=$(_find_cover_in_dir "$album_dir") || true
    if [[ -n "$found" ]]; then
        printf '%s\n' "$found"
        return 0
    fi

    dir_name="${album_dir##*/}"
    if [[ "$dir_name" =~ $disc_dir_re ]]; then
        parent="${album_dir%/*}"
        [[ "$parent" == "$album_dir" ]] && parent="."
        found=$(_find_cover_in_dir "$parent") || true
        if [[ -n "$found" ]]; then
            printf '%s\n' "$found"
            return 0
        fi
    fi

    return 1
}

# Shared filesystem artwork lookup for every local-file backend.
# Emits a real cover path or the transparent default image.
get_cover_for_file() {
    local file="$1" art=""
    if [[ -f "$file" ]]; then
        art=$(find_cover "${file%/*}") || true
    fi
    if [[ -n "$art" && -f "$art" ]]; then
        printf '%s\n' "$art"
    else
        printf '%s\n' "$DEFAULT_IMG"
    fi
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
    local art

    # Cache per album directory, including the no-cover result.
    if [[ -v cover_cache["$album_dir"] ]]; then
        printf '%s\n' "${cover_cache["$album_dir"]}"
        return 0
    fi

    art=$(get_cover_for_file "$file")
    cover_cache["$album_dir"]="$art"
    printf '%s\n' "$art"
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

