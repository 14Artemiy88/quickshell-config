#!/bin/bash
# Shared Player backend helpers. All sources stay relative to this file's
# location; path expansion avoids a dirname process on every Player poll.
PLAYER_LIB_PATH="${BASH_SOURCE[0]}"
PLAYER_LIB_DIR="${PLAYER_LIB_PATH%/*}"
[[ "$PLAYER_LIB_DIR" != "$PLAYER_LIB_PATH" ]] || PLAYER_LIB_DIR=.
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
# Assign the source key into the caller's variable so the polled snapshot path
# avoids an extra command-substitution subshell. Keep the stdout wrapper for
# existing callers and tests.
mpv_snapshot_key_into() {
    local source_path="${1:-}" output_var="${2:-}" digest=""
    [[ -n "$source_path" ]] || return 1
    [[ "$output_var" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] || return 1
    # sha256sum already emits its digest as the first whitespace-delimited
    # field. Extracting it with Bash avoids a second external parser process.
    digest=$(printf '%s' "$source_path" | sha256sum) || return 1
    digest="${digest%% *}"
    [[ "$digest" =~ ^[0-9a-f]{64}$ ]] || return 1
    printf -v "$output_var" '%s' "${digest:0:24}"
}

mpv_snapshot_key() {
    local result_key=""
    mpv_snapshot_key_into "${1:-}" result_key || return 1
    printf '%s\n' "$result_key"
}

mpv_store_latest_snapshot_for_key() {
    local key="${1:-}" snapshot_name="${2:-}" pointer tmp
    [[ "$key" =~ ^[0-9a-f]{24}$ && -d "$IMG_PATH" ]] || return 1
    pointer="$IMG_PATH/.mpv-${key}.latest"
    if [[ -z "$snapshot_name" ]]; then
        snapshot_name="-"
    elif [[ ! "$snapshot_name" =~ ^mpv-${key}-[0-9]+(-[0-9]+)*\.png$ ]]; then
        return 1
    fi
    tmp="$pointer.$$.${RANDOM}.tmp"
    if ! printf '%s\n' "$snapshot_name" > "$tmp"; then
        rm -f -- "$tmp" 2>/dev/null || true
        return 1
    fi
    mv -f -- "$tmp" "$pointer" || {
        rm -f -- "$tmp" 2>/dev/null || true
        return 1
    }
}

# Caller-variable API for the hot polling path. The stdout-based helper below
# remains compatible for existing callers; normal sidecar hits avoid an extra
# command-substitution subshell when called through this API.
mpv_latest_snapshot_for_key_into() {
    local key="${1:-}" output_var="${2:-}" latest="" snapshot_name="" pointer=""
    [[ "$key" =~ ^[0-9a-f]{24}$ && -d "$IMG_PATH" ]] || return 1
    [[ "$output_var" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] || return 1
    pointer="$IMG_PATH/.mpv-${key}.latest"

    # The sidecar is atomically updated when a snapshot is published. A regular
    # cache hit needs only a Bash read and file existence check, not find/sort/head.
    if [[ -f "$pointer" ]]; then
        IFS= read -r snapshot_name < "$pointer" || snapshot_name=""
        if [[ "$snapshot_name" == "-" ]]; then
            printf -v "$output_var" '%s' ''
            return 1
        fi
        if [[ "$snapshot_name" =~ ^mpv-${key}-[0-9]+(-[0-9]+)*\.png$ && -s "$IMG_PATH/$snapshot_name" ]]; then
            printf -v "$output_var" '%s' "$IMG_PATH/$snapshot_name"
            return 0
        fi
    fi

    # One-time migration/fallback for snapshots created by older versions, or
    # recovery if the indexed file was externally removed.
    latest=$(find "$IMG_PATH" -maxdepth 1 -type f -name "mpv-${key}-*.png" \
        -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -n 1) || true
    if [[ -n "$latest" ]]; then
        latest="${latest#* }"
        snapshot_name="${latest##*/}"
        if [[ "$snapshot_name" =~ ^mpv-${key}-[0-9]+(-[0-9]+)*\.png$ && -s "$latest" ]]; then
            mpv_store_latest_snapshot_for_key "$key" "$snapshot_name" || true
            printf -v "$output_var" '%s' "$latest"
            return 0
        fi
    fi

    # Remember a clean miss as well. Failed/unsupported sources should not
    # relaunch a find/sort/head pipeline on every poll while retry is throttled.
    mpv_store_latest_snapshot_for_key "$key" "" || true
    printf -v "$output_var" '%s' ''
    return 1
}

mpv_latest_snapshot_for_key() {
    local result_path=""
    if mpv_latest_snapshot_for_key_into "${1:-}" result_path; then
        printf '%s\n' "$result_path"
        return 0
    fi
    return 1
}

create_mpv_snapshot() {
    local source_path="${1:-}" position="${2:-}" key stamp temp_path final_path
    [[ -n "$source_path" && "$position" =~ ^[0-9]+([.][0-9]+)?$ ]] || return 1
    command -v ffmpeg >/dev/null 2>&1 || return 1
    command -v timeout >/dev/null 2>&1 || return 1
    mkdir -p "$IMG_PATH" 2>/dev/null || return 1

    mpv_snapshot_key_into "$source_path" key || return 1
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
            mpv_store_latest_snapshot_for_key "$key" "${final_path##*/}" || true
            printf '%s\n' "$final_path"
            return 0
        fi
    fi

    rm -f -- "$temp_path" 2>/dev/null || true
    return 1
}

get_mpv_snapshot() {
    local source_path="${1:-}" position="${2:-}" force="${3:-false}" ttl="${4:-60}"
    local key latest="" cached_latest="" modified now captured="" attempt_path attempt_modified
    [[ -n "$source_path" && "$position" =~ ^[0-9]+([.][0-9]+)?$ ]] || return 1
    mpv_snapshot_key_into "$source_path" key || return 1
    mpv_latest_snapshot_for_key_into "$key" cached_latest || cached_latest=""
    latest="$cached_latest"
    attempt_path="$IMG_PATH/.mpv-${key}.attempt"

    if [[ "$force" != "true" ]]; then
        if [[ -n "$latest" && -s "$latest" ]]; then
            modified=$(stat -c %Y -- "$latest" 2>/dev/null || printf '0')
            # Bash's printf time conversion is a builtin. Avoid starting a
            # separate date process on every Player poll; keep date as a
            # compatibility fallback for older Bash versions.
            if ! printf -v now '%(%s)T' -1 2>/dev/null; then
                now=$(date +%s)
            fi
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
            if ! printf -v now '%(%s)T' -1 2>/dev/null; then
                now=$(date +%s)
            fi
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
    local img_url="${1:-}" requested_player="${2:-}" image_path key tmp_path converted_path attempt_path lock_path lock_fd
    local attempt_modified now curl_output

    # Some backends can omit artUrl even when playerctl has it. When the caller
    # already selected an MPRIS backend, query that exact player: an unqualified
    # playerctl request can return artwork from a different active player and
    # mix covers when, for example, Spotify and a browser play simultaneously.
    if [[ -z "$img_url" ]]; then
        if [[ -n "$requested_player" ]]; then
            img_url=$(playerctl -p "$requested_player" metadata -f '{{ mpris:artUrl }}' 2>/dev/null) || img_url=""
        else
            # Keep the legacy unqualified lookup for callers that do not know a
            # backend, but all MPRIS metadata calls pass their selected player.
            img_url=$(playerctl metadata -f '{{ mpris:artUrl }}' 2>/dev/null) || img_url=""
        fi
        [[ -n "$img_url" ]] || { printf '%s\n' "$DEFAULT_IMG"; return 0; }
    fi

    # Only accept the URL schemes this helper is expected to load. MPRIS art
    # commonly uses http(s) or a local file URI; don't let arbitrary schemes
    # reach curl.
    case "$img_url" in
        http://*|https://*|file://*) ;;
        *) printf '%s\n' "$DEFAULT_IMG"; return 0 ;;
    esac

    # Hash the full URL before touching the cache directory. On the high-frequency
    # warm-cache path, the cached artwork already proves that IMG_PATH exists, so
    # do not launch `mkdir -p` on every Player poll.
    # Hash the full URL rather than using only its basename: different albums
    # frequently publish images named cover.jpg, and query strings may contain
    # distinct artwork versions or tokens.
    local url_digest=""
    url_digest=$(printf '%s' "$img_url" | sha256sum) || {
        printf '%s\n' "$DEFAULT_IMG"
        return 0
    }
    url_digest="${url_digest%% *}"
    [[ "$url_digest" =~ ^[0-9a-f]{64}$ ]] || {
        printf '%s\n' "$DEFAULT_IMG"
        return 0
    }
    key="${url_digest:0:32}"
    image_path="$IMG_PATH/mpris-art-${key}.png"
    attempt_path="$IMG_PATH/.mpris-art-${key}.attempt"
    lock_path="$IMG_PATH/.mpris-art-${key}.lock"

    if [[ -s "$image_path" ]]; then
        printf '%s\n' "$image_path"
        return 0
    fi

    # The cache miss path may need to create the runtime directory before the
    # lock file and temporary download can be opened. Keep this after the hit
    # check so normal cached Player polls require no mkdir process.
    mkdir -p "$IMG_PATH" 2>/dev/null || {
        printf '%s\n' "$DEFAULT_IMG"
        return 0
    }

    # Multiple Player backends/polls can resolve the same URL simultaneously.
    # Use a non-blocking per-URL lock so only one process performs curl and
    # ImageMagick work. Other callers never wait behind a slow art host.
    if ! command -v flock >/dev/null 2>&1 || ! exec {lock_fd}>"$lock_path"; then
        printf '%s\n' "$DEFAULT_IMG"
        return 0
    fi
    if ! flock -n "$lock_fd"; then
        exec {lock_fd}>&-
        # The other caller may have finished between the initial cache check
        # and lock attempt; use its completed image if it is already published.
        if [[ -s "$image_path" ]]; then
            printf '%s\n' "$image_path"
        else
            printf '%s\n' "$DEFAULT_IMG"
        fi
        return 0
    fi
    # Refresh the lock's mtime while held; the small per-URL lock file is kept
    # to avoid unsafe unlink/recreate races between concurrent processes.
    touch "$lock_path" 2>/dev/null || true

    # Recheck the cache after acquiring the lock. Another caller could have
    # published the image immediately before this caller acquired it.
    if [[ -s "$image_path" ]]; then
        flock -u "$lock_fd" 2>/dev/null || true
        exec {lock_fd}>&-
        printf '%s\n' "$image_path"
        return 0
    fi

    # Rate-limit failures only after serializing callers for this URL.
    if [[ -f "$attempt_path" ]]; then
        attempt_modified=$(stat -c %Y -- "$attempt_path" 2>/dev/null || printf '0')
        now=$(date +%s)
        if [[ "$attempt_modified" =~ ^[0-9]+$ ]] && (( now - attempt_modified < 60 )); then
            flock -u "$lock_fd" 2>/dev/null || true
            exec {lock_fd}>&-
            printf '%s\n' "$DEFAULT_IMG"
            return 0
        fi
    fi

    tmp_path=$(mktemp "$IMG_PATH/.mpris-art-${key}.XXXXXX.download") || {
        date +%s > "$attempt_path" 2>/dev/null || true
        flock -u "$lock_fd" 2>/dev/null || true
        exec {lock_fd}>&-
        printf '%s\n' "$DEFAULT_IMG"
        return 0
    }
    # Mark the start as well, so an interrupted download is throttled too.
    date +%s > "$attempt_path" 2>/dev/null || true

    # A timeout is important here: this function runs while producing player
    # metadata and a slow cover host must not stall the whole player poll.
    if timeout 5s curl --proto '=http,https,file' -fLsS \
        --connect-timeout 2 --max-time 4 \
        --output "$tmp_path" "$img_url" 2>/dev/null && [[ -s "$tmp_path" ]] &&
        command -v mogrify >/dev/null 2>&1; then
        # The temporary input has no image suffix; ImageMagick writes a separate
        # PNG next to it, which can be atomically published under the final URL key.
        if mogrify -format png "$tmp_path" >/dev/null 2>&1; then
            converted_path="${tmp_path%.*}.png"
            if [[ -s "$converted_path" ]] && mv -f -- "$converted_path" "$image_path"; then
                rm -f -- "$tmp_path" "$attempt_path" 2>/dev/null || true
                flock -u "$lock_fd" 2>/dev/null || true
                exec {lock_fd}>&-
                # Reap old lock/attempt metadata occasionally without touching
                # current entries; a held lock has a freshly updated mtime.
                find "$IMG_PATH" -maxdepth 1 -type f -name '.mpris-art-*.lock' -mmin +1440 -delete 2>/dev/null || true
                printf '%s\n' "$image_path"
                return 0
            fi
        fi
    fi

    rm -f -- "$tmp_path" "${tmp_path%.*}.png" 2>/dev/null || true
    # Keep a recent failure timestamp so the next polling cycle returns quickly.
    date +%s > "$attempt_path" 2>/dev/null || true
    flock -u "$lock_fd" 2>/dev/null || true
    exec {lock_fd}>&-
    printf '%s\n' "$DEFAULT_IMG"
    return 0
}

# Format milliseconds directly into a caller-owned variable. The stdout
# wrapper is retained for existing call sites; polling paths can avoid the
# command-substitution subshell by using timeFormat_into.
timeFormat_into() {
    local output_var="$1" milliseconds="$2"
    local seconds=$((milliseconds / 1000))
    [[ "$output_var" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] || return 1
    printf -v "$output_var" "%02d:%02d:%02d" \
        $((seconds / 3600)) $(((seconds % 3600) / 60)) $((seconds % 60))
}

timeFormat() {
    local formatted=""
    timeFormat_into formatted "$1" || return 1
    printf '%s\n' "$formatted"
}

# Escape a Player field as a JSON string without launching jq on each poll.
# Bash cannot store NUL bytes; all other control characters are escaped, while
# valid UTF-8 bytes pass through unchanged. Callers keep raw metadata intact and
# this helper owns escaping exactly once, including quotes and backslashes.
player_json_escape_into() {
    local output_var="${1:-}" value="${2-}" char escaped_char out="" i code
    [[ "$output_var" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] || return 2
    local LC_ALL=C
    for ((i = 0; i < ${#value}; i++)); do
        char="${value:i:1}"
        case "$char" in
            $'\\') out+='\\' ;;
            '"') out+='\"' ;;
            $'\b') out+='\b' ;;
            $'\f') out+='\f' ;;
            $'\n') out+='\n' ;;
            $'\r') out+='\r' ;;
            $'\t') out+='\t' ;;
            *)
                printf -v code '%d' "'$char"
                if (( code < 32 || code == 127 )); then
                    printf -v escaped_char '\\u%04x' "$code"
                    out+="$escaped_char"
                else
                    out+="$char"
                fi
                ;;
        esac
    done
    printf -v "$output_var" '%s' "$out"
}

# Construct the string-only Player payload in the caller's scope. Keep the
# same fields/types as the former jq --arg serializer, but emit compact JSON so
# every successful high-frequency Player poll avoids one external jq process.
player_build_json_into() {
    local output_var="${1:-}"
    shift || true
    local first_line="${1-}" second_line="${2-}" third_line="${3-}" timeleft="${4-}"
    local position="${5-}" status="${6-}" image="${7-}" artist="${8-}"
    local player="${9-}" title_class="${10-}" duration="${11-}"
    local first_json second_json third_json timeleft_json position_json status_json
    local image_json artist_json player_json title_class_json duration_json serialized_player_json
    [[ "$output_var" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] || return 2

    player_json_escape_into first_json "$first_line" || return 1
    player_json_escape_into second_json "$second_line" || return 1
    player_json_escape_into third_json "$third_line" || return 1
    player_json_escape_into timeleft_json "$timeleft" || return 1
    player_json_escape_into position_json "$position" || return 1
    player_json_escape_into status_json "$status" || return 1
    player_json_escape_into image_json "$image" || return 1
    player_json_escape_into artist_json "$artist" || return 1
    player_json_escape_into player_json "$player" || return 1
    player_json_escape_into title_class_json "$title_class" || return 1
    player_json_escape_into duration_json "$duration" || return 1

    serialized_player_json="{\"first_line\":\"$first_json\",\"second_line\":\"$second_json\",\"third_line\":\"$third_json\",\"timeleft\":\"$timeleft_json\",\"position\":\"$position_json\",\"status\":\"$status_json\",\"image\":\"$image_json\",\"text\":\"$artist_json\",\"player\":\"$player_json\",\"title_class\":\"$title_class_json\",\"duration\":\"$duration_json\"}"
    printf -v "$output_var" '%s' "$serialized_player_json"
}

# Получение метаданных Mopidy
get_json() {
    # Параметры по умолчанию
    local first_line="" second_line="" third_line="" timeleft="" pos_ms="" dur_ms=""
    local status="" image="" artist="" player="" title_class duration_ms="" position_percent="" payload=""

    title_class="$DEFAULT_TITLE_CLASS"
    # Парсинг аргументов
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --first_line) first_line="${2-}"; shift 2 ;;
            --second_line) second_line="${2-}"; shift 2 ;;
            --third_line) third_line="${2-}"; shift 2 ;;
            --timeleft) timeleft="${2-}"; shift 2 ;;
            --pos_ms) pos_ms="${2-}"; shift 2 ;;
            --dur_ms) dur_ms="${2-}"; duration_ms="${2-}"; shift 2 ;;
            --status) status="${2-}"; shift 2 ;;
            --image) image="${2-}"; shift 2 ;;
            --artist) artist="${2-}"; shift 2 ;;
            --player) player="${2-}"; shift 2 ;;
            --title_class) title_class="${2-}"; shift 2 ;;
            *) shift ;; # игнорируем неизвестные параметры
        esac
    done

    # Calculate progress only when both values form a usable range. Keep
    # position empty for metadata-only/live items without a known duration;
    # Player.qml already treats an empty position as zero for layout, while the
    # payload no longer falsely claims a real 0% measurement.
    if [[ "$pos_ms" =~ ^[0-9]+$ && "$dur_ms" =~ ^[0-9]+$ ]] && (( dur_ms > 0 )); then
        position_percent=$(( (pos_ms * 100) / dur_ms ))
        (( position_percent < 0 )) && position_percent=0
        (( position_percent > 100 )) && position_percent=100
    fi

    player_build_json_into payload \
        "$first_line" "$second_line" "$third_line" "$timeleft" \
        "$position_percent" "$status" "$image" "$artist" "$player" "$title_class" "$duration_ms" || return 1
    printf '%s\n' "$payload"
    exit 0
}
