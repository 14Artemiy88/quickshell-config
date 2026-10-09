#!/bin/bash

MOPIDY_RPC_URL="${MOPIDY_RPC_URL:-http://localhost:6680/mopidy/rpc}"

mopidy_rpc() {
    local method="$1"
    local params="{}"
    [[ -n "${2:-}" ]] && params="$2"
    curl -sS --connect-timeout 1 --max-time 2 \
        -H 'Content-Type: application/json' \
        -d "$(jq -cn --argjson params "$params" --arg method "$method" '{jsonrpc:"2.0",id:1,method:$method,params:$params}')" \
        "$MOPIDY_RPC_URL" 2>/dev/null
}

# Validate artwork before handing its path to QML. A non-empty HTTP error page
# is not a usable cover and otherwise hides the Player's fallback text.
mopidy_is_image_file() {
    local path="$1" mime header
    [[ -s "$path" ]] || return 1
    if command -v file >/dev/null 2>&1; then
        mime=$(file --brief --mime-type -- "$path" 2>/dev/null) || return 1
        [[ "$mime" == image/* ]] && return 0
    fi
    header=$(od -An -tx1 -N12 -- "$path" 2>/dev/null | tr -d ' \n')
    case "$header" in
        89504e470d0a1a0a*|ffd8ff*|474946383761*|474946383961*|424d*) return 0 ;;
        52494646????????57454250*) return 0 ;;
        *) return 1 ;;
    esac
}

# Keep compatibility with the pre-v551 artwork path when the Mopidy API does
# not return a usable image. This path was used by the working version before
# the new URI based lookup was introduced.
mopidy_cover_fallback() {
    local legacy="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/album_cover.png"
    if mopidy_is_image_file "$legacy"; then
        printf '%s\n' "$legacy"
    else
        printf '%s\n' "$DEFAULT_IMG"
    fi
}

# Resolve Mopidy Image URIs to a local file for the Player widget.
# Mopidy's core.library.get_images commonly returns paths like /local/<hash>.jpeg,
# which must be requested from the same HTTP server as the JSON-RPC endpoint.
mopidy_image_url() {
    local image_uri="$1" base
    case "$image_uri" in
        http://*|https://*) printf '%s\n' "$image_uri"; return 0 ;;
        file://*) printf '%s\n' "${image_uri#file://}"; return 0 ;;
        /*) ;;
        *) image_uri="/$image_uri" ;;
    esac

    base="${MOPIDY_RPC_URL%/mopidy/rpc}"
    if [[ "$base" == "$MOPIDY_RPC_URL" ]]; then
        base="${MOPIDY_RPC_URL%%/mopidy/*}"
    fi
    printf '%s%s\n' "$base" "$image_uri"
}

# Convert local Mopidy file URIs to a filesystem path so local Mopidy tracks
# use the exact same cover search as DeaDBeeF. Remote/library URIs return empty.
mopidy_local_track_path() {
    local uri="$1"
    command -v python3 >/dev/null 2>&1 || return 0
    python3 - "$uri" <<'PYURI'
import sys
from urllib.parse import urlsplit, unquote
uri = sys.argv[1]
try:
    parsed = urlsplit(uri)
    if parsed.scheme == "file" and parsed.netloc in ("", "localhost"):
        print(unquote(parsed.path))
    elif not parsed.scheme and uri.startswith("/"):
        print(unquote(uri))
except Exception:
    pass
PYURI
}

mopidy_cover_for_track() {
    local track_uri="$1" album_uri="${2:-}" cache_dir key marker stamp art_uri now
    local image_url url_path ext output_path tmp params images_json failed_stamp failed_at
    local local_track_path local_cover
    [[ -n "$track_uri" ]] || { mopidy_cover_fallback; return 0; }

    # Use the shared adjacent-file lookup first for local tracks. This keeps
    # DeaDBeeF and local-file Mopidy consistent, and avoids the API/cache path
    # selecting artwork belonging to a different album.
    local_track_path=$(mopidy_local_track_path "$track_uri")
    if [[ -n "$local_track_path" && -f "$local_track_path" ]]; then
        local_cover=$(get_cover_for_file "$local_track_path")
        if [[ -n "$local_cover" && "$local_cover" != "$DEFAULT_IMG" && -s "$local_cover" ]]; then
            printf '%s\n' "$local_cover"
            return 0
        fi
    fi

    cache_dir="$QS_CACHE_DIR/mopidy-covers"
    mkdir -p "$cache_dir" 2>/dev/null || { mopidy_cover_fallback; return 0; }
    key=$(printf '%s' "$track_uri" | sha256sum | awk '{print $1}')
    marker="$cache_dir/$key.uri"
    stamp="$cache_dir/$key.checked"

    # Cache image URI per track so Player's frequent metadata polling doesn't
    # repeatedly call get_images. Negative results are retried after 30 seconds.
    if [[ -f "$marker" ]]; then
        IFS= read -r art_uri < "$marker" || true
        if [[ -z "$art_uri" ]]; then
            now=$(date +%s)
            local checked=0
            [[ -f "$stamp" ]] && read -r checked < "$stamp"
            if [[ "$checked" =~ ^[0-9]+$ ]] && (( now - checked < 30 )); then
                mopidy_cover_fallback
                return 0
            fi
        fi
    fi

    if [[ ! -f "$marker" || -z "$art_uri" ]]; then
        params=$(jq -cn --arg track "$track_uri" --arg album "$album_uri" \
            '{uris: ([$track, $album] | map(select(length > 0)) | unique)}')
        images_json=$(mopidy_rpc 'core.library.get_images' "$params")
        art_uri=$(jq -r --arg track "$track_uri" --arg album "$album_uri" '
            def best($uri): ((.result[$uri] // []) | sort_by(((.width // 0) * (.height // 0))) | last | .uri // "");
            (best($track)) as $track_image |
            if $track_image != "" then $track_image else best($album) end
        ' <<< "$images_json" 2>/dev/null)
        [[ "$art_uri" == "null" ]] && art_uri=""
        printf '%s\n' "$art_uri" > "$marker"
        date +%s > "$stamp"
    fi

    if [[ -z "$art_uri" ]]; then
        mopidy_cover_fallback
        return 0
    fi

    # Some backends return a local file URI directly; use it without copying.
    case "$art_uri" in
        file://*)
            output_path="${art_uri#file://}"
            if mopidy_is_image_file "$output_path"; then
                printf '%s\n' "$output_path"
                return 0
            fi
            ;;
        /*)
            if [[ "$art_uri" != /local/* ]] && mopidy_is_image_file "$art_uri"; then
                printf '%s\n' "$art_uri"
                return 0
            fi
            ;;
    esac

    image_url=$(mopidy_image_url "$art_uri")
    url_path="${art_uri%%\?*}"
    url_path="${url_path%%\#*}"
    ext="${url_path##*.}"
    ext="${ext,,}"
    case "$ext" in
        jpg|jpeg|png|webp|gif|bmp) ;;
        *) ext="jpg" ;;
    esac
    output_path="$cache_dir/$key.$ext"
    failed_stamp="$cache_dir/$key.download-failed"
    # Remove corrupt cached responses created by older attempts.
    if [[ -e "$output_path" ]] && ! mopidy_is_image_file "$output_path"; then
        rm -f "$output_path"
    fi
    if [[ ! -s "$output_path" ]]; then
        now=$(date +%s)
        failed_at=0
        [[ -f "$failed_stamp" ]] && read -r failed_at < "$failed_stamp"
        if [[ "$failed_at" =~ ^[0-9]+$ ]] && (( now - failed_at < 30 )); then
            mopidy_cover_fallback
            return 0
        fi
        tmp="$output_path.part.$$"
        if curl -fsSL --connect-timeout 1 --max-time 4 "$image_url" -o "$tmp" 2>/dev/null && mopidy_is_image_file "$tmp"; then
            mv -f "$tmp" "$output_path"
            rm -f "$failed_stamp"
        else
            rm -f "$tmp"
            date +%s > "$failed_stamp"
            mopidy_cover_fallback
            return 0
        fi
    fi
    if mopidy_is_image_file "$output_path"; then
        printf '%s\n' "$output_path"
    else
        rm -f "$output_path"
        mopidy_cover_fallback
    fi
}

mopidy_control_log() {
    local state_dir="${QS_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/quickshell-widgets}"
    mkdir -p "$state_dir" 2>/dev/null || return 0
    printf '[%s] %s\n' "$(date '+%F %T')" "$*" >> "$state_dir/mopidy-control.log" 2>/dev/null || true
}

mopidy_force_play_current_track() {
    # Recovery path for backends which report `playing` after resume but do not
    # restart the underlying provider. Stop and explicitly play the active tlid,
    # then restore the position that was saved before the recovery.
    local tlid="$1" previous_pos="$2" params response state current_pos attempt
    [[ "$tlid" =~ ^[0-9]+$ ]] || return 1

    mopidy_rpc 'core.playback.stop' >/dev/null
    params=$(jq -cn --argjson tlid "$tlid" '{tlid:$tlid}')
    response=$(mopidy_rpc 'core.playback.play' "$params")
    if [[ -n "$(jq -r '.error.message // empty' <<< "$response" 2>/dev/null)" ]]; then
        mopidy_control_log "forced play failed: $(jq -r '.error.message' <<< "$response" 2>/dev/null)"
        return 1
    fi

    # Wait for playback's clock to move before seeking; some providers ignore
    # a seek issued immediately after changing tracks.
    for attempt in {1..10}; do
        sleep 0.15
        state=$(mopidy_rpc 'core.playback.get_state' | jq -r '.result // empty' 2>/dev/null)
        current_pos=$(mopidy_rpc 'core.playback.get_time_position' | jq -r '.result // 0' 2>/dev/null)
        [[ "$state" == "playing" ]] || continue
        [[ "$current_pos" =~ ^[0-9]+$ && "$current_pos" -gt 0 ]] && break
    done

    if [[ "$previous_pos" =~ ^[0-9]+$ && "$previous_pos" -gt 0 ]]; then
        params=$(jq -cn --argjson position "$previous_pos" '{time_position:$position}')
        response=$(mopidy_rpc 'core.playback.seek' "$params")
        if [[ -n "$(jq -r '.error.message // empty' <<< "$response" 2>/dev/null)" ]]; then
            mopidy_control_log "position restore failed: $(jq -r '.error.message' <<< "$response" 2>/dev/null)"
        fi
    fi
    mopidy_control_log "restarted current track via tlid=$tlid after resume did not advance playback"
    return 0
}

mopidy_resume_current_track() {
    local current_tl_response tlid previous_pos track_length response state current_pos attempt
    current_tl_response=$(mopidy_rpc 'core.playback.get_current_tl_track')
    tlid=$(jq -r '.result.tlid // empty' <<< "$current_tl_response" 2>/dev/null)
    track_length=$(jq -r '.result.track.length // 0' <<< "$current_tl_response" 2>/dev/null)
    previous_pos=$(mopidy_rpc 'core.playback.get_time_position' | jq -r '.result // 0' 2>/dev/null)

    # Use Mopidy's dedicated resume method first. Unlike calling play() without
    # a tlid, it is specifically intended to resume the active playback provider.
    response=$(mopidy_rpc 'core.playback.resume')
    if [[ -n "$(jq -r '.error.message // empty' <<< "$response" 2>/dev/null)" ]]; then
        mopidy_control_log "core.playback.resume returned error: $(jq -r '.error.message' <<< "$response" 2>/dev/null)"
        mopidy_force_play_current_track "$tlid" "$previous_pos"
        return
    fi

    # Do not trust only get_state: some backends can flip the core state while
    # their playback clock remains frozen. Confirm that a finite track advances.
    for attempt in {1..7}; do
        sleep 0.2
        state=$(mopidy_rpc 'core.playback.get_state' | jq -r '.result // empty' 2>/dev/null)
        current_pos=$(mopidy_rpc 'core.playback.get_time_position' | jq -r '.result // 0' 2>/dev/null)
        [[ "$state" == "playing" ]] || continue

        # For streams without a known length, state=playing is the only useful
        # signal. For normal tracks require the playback position to actually move.
        if ! [[ "$track_length" =~ ^[0-9]+$ ]] || (( track_length <= 0 )); then
            return 0
        fi
        if [[ "$current_pos" =~ ^[0-9]+$ && "$previous_pos" =~ ^[0-9]+$ ]] && (( current_pos != previous_pos )); then
            return 0
        fi
    done

    mopidy_control_log "resume did not advance playback (state=${state:-unknown}, position=${current_pos:-unknown}); forcing current track start and restoring position"
    mopidy_force_play_current_track "$tlid" "$previous_pos"
}

mopidy_pause_toggle() {
    local state response
    state=$(mopidy_rpc 'core.playback.get_state' | jq -r '.result // empty')
    case "$state" in
        playing)
            response=$(mopidy_rpc 'core.playback.pause')
            if [[ -n "$(jq -r '.error.message // empty' <<< "$response" 2>/dev/null)" ]]; then
                mopidy_control_log "pause failed: $(jq -r '.error.message' <<< "$response" 2>/dev/null)"
                return 1
            fi
            ;;
        paused) mopidy_resume_current_track ;;
        stopped) mopidy_rpc 'core.playback.play' >/dev/null ;;
        *) return 1 ;;
    esac
}

mopidy_next() {
    mopidy_rpc 'core.playback.next' >/dev/null
}

mopidy_prev() {
    mopidy_rpc 'core.playback.previous' >/dev/null
}

mopidy_seek_percent() {
    local percent="$1"
    local duration_ms="$2"
    [[ "$percent" =~ ^[0-9]+([.][0-9]+)?$ ]] || return 1
    [[ "$duration_ms" =~ ^[0-9]+$ ]] || return 1
    (( duration_ms > 0 )) || return 1

    local target_ms
    target_ms=$(awk -v p="$percent" -v d="$duration_ms" 'BEGIN {printf "%d", (p * d) / 100}')
    mopidy_rpc 'core.playback.seek' "$(jq -cn --argjson t "$target_ms" '{time_position:$t}')" >/dev/null
}

get_mopidy_player_metadata() {
    if ! pgrep -x mopidy >/dev/null; then
        return
    fi

    local rpc_data current trackTime current_album current_album_date current_artist current_length current_title
    local current_track_uri current_album_uri cover_image
    local format_album time_left cls state

    rpc_data=$(curl -sS --connect-timeout 1 --max-time 2 \
        -H 'Content-Type: application/json' \
        -d '[
            {"jsonrpc":"2.0","id":1,"method":"core.playback.get_state"},
            {"jsonrpc":"2.0","id":2,"method":"core.playback.get_current_tl_track"},
            {"jsonrpc":"2.0","id":3,"method":"core.playback.get_time_position"}
        ]' \
        "$MOPIDY_RPC_URL" 2>/dev/null)

    state=$(jq -r '.[] | select(.id == 1) | .result // empty' <<< "$rpc_data")
    [[ "$state" == "playing" || "$state" == "paused" ]] || return

    current=$(jq -c '.[] | select(.id == 2) | .result // empty' <<< "$rpc_data")
    trackTime=$(jq -r '.[] | select(.id == 3) | .result // 0' <<< "$rpc_data")
    [[ -n "$current" && "$current" != "null" ]] || return

    current_album=$(jq -r '.track.album.name // empty' <<< "$current")
    current_album_date=$(jq -r '.track.album.date // empty' <<< "$current")
    current_artist=$(jq -r '.track.artists[0].name // empty' <<< "$current")
    current_length=$(jq -r '.track.length // 0' <<< "$current")
    current_title=$(jq -r '.track.name // empty' <<< "$current")
    current_track_uri=$(jq -r '.track.uri // empty' <<< "$current")
    current_album_uri=$(jq -r '.track.album.uri // empty' <<< "$current")

    format_album="$current_album_date"
    [[ -n "$current_album" ]] && format_album+=" - $current_album"
    [[ -z "$format_album" ]] && format_album=""
    [[ -z "$current_artist" ]] && current_artist="music"

    time_left=$(timeFormat $((current_length - trackTime)))
    time_left=${time_left##00:}

    cls=$DEFAULT_TITLE_CLASS
    [[ ${#current_title} -gt 10 ]] && cls="more_ten"

    local status_icon="${icons[paused]}"
    [[ "$state" == "playing" ]] && status_icon="${icons[playing]}"

    cover_image=$(mopidy_cover_for_track "$current_track_uri" "$current_album_uri")
    [[ -s "$cover_image" ]] || cover_image="$DEFAULT_IMG"

    get_json \
        --first_line "$current_title" \
        --second_line "$format_album" \
        --timeleft "$time_left" \
        --pos_ms "$trackTime" \
        --dur_ms "$current_length" \
        --status "$status_icon" \
        --image "$cover_image" \
        --artist "$current_artist" \
        --player "mopidy" \
        --title_class "$cls"
}
