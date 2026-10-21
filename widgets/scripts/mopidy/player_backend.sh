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

# If the current-playback snapshot omits artist tags, try the library metadata
# and the current tracklist entry. Some Mopidy backends expose richer metadata
# there than in core.playback.get_current_tl_track.
mopidy_lookup_artist_fallback() {
    local uri="${1:-}" tlid="${2:-}" payload response
    [[ -n "$uri" ]] || return 0
    payload=$(jq -cn --arg uri "$uri" '[
        {jsonrpc:"2.0",id:10,method:"core.library.lookup",params:{uris:[$uri]}},
        {jsonrpc:"2.0",id:11,method:"core.tracklist.get_tl_tracks",params:{}}
    ]') || return 0
    response=$(curl -sS --connect-timeout 1 --max-time 2 \
        -H 'Content-Type: application/json' \
        -d "$payload" \
        "$MOPIDY_RPC_URL" 2>/dev/null) || return 0
    jq -r --arg uri "$uri" --arg tlid "$tlid" '
        def names:
          if type == "array" then
            map(if type == "object" then (.name // "") elif type == "string" then . else "" end)
            | map(select(type == "string" and length > 0)) | join(", ")
          elif type == "object" then (.name // "")
          elif type == "string" then .
          else "" end;
        def artist_for_track:
          (.artists | names) as $track_artists
          | (.artist | names) as $track_artist
          | (.album.artists | names) as $album_artists
          | (.album.artist | names) as $album_artist
          | (.performers | names) as $performers
          | if $track_artists != "" then $track_artists
            elif $track_artist != "" then $track_artist
            elif $album_artists != "" then $album_artists
            elif $album_artist != "" then $album_artist
            else $performers end;
        . as $responses
        | ([ $responses[] | select(.id == 10) | .result[$uri][]? | artist_for_track | select(length > 0) ][0] // "") as $library_artist
        | ([ $responses[] | select(.id == 11) | .result[]? | select((.tlid | tostring) == $tlid) | .track | artist_for_track | select(length > 0) ][0] // "") as $queue_artist
        | if $library_artist != "" then $library_artist else $queue_artist end
    ' <<< "$response" 2>/dev/null || true
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
    local uri="$1" uri_lower="${1,,}"
    # Most Mopidy URIs are remote/library identifiers, not filesystem paths.
    # Return on those common polling paths before starting Python; retain Python
    # URL decoding for local file URIs and absolute filesystem paths.
    case "$uri_lower" in
        file://*|/*) ;;
        *) return 0 ;;
    esac
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

# Set a named variable in the caller to the current epoch second without
# launching `date` on supported Bash versions. The older-Bash fallback remains
# for systems where EPOCHSECONDS is not available.
mopidy_set_epoch_seconds() {
    local target_var="${1:-}" current="${EPOCHSECONDS:-}"
    [[ "$target_var" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] || return 1
    if [[ ! "$current" =~ ^[0-9]+$ ]]; then
        current=$(date +%s) || return 1
    fi
    [[ "$current" =~ ^[0-9]+$ ]] || return 1
    printf -v "$target_var" '%s' "$current"
}

mopidy_cover_for_track() {
    local track_uri="$1" album_uri="${2:-}" cache_dir key marker stamp art_uri now
    local image_url url_path ext output_path tmp params images_json failed_stamp failed_at output_valid=0
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
    # Player polls cover metadata frequently. The cache directory is stable
    # after first use, so avoid spawning `mkdir -p` on every cache lookup.
    # Keep the guarded creation for first use and for recovery if it vanished.
    if [[ ! -d "$cache_dir" ]]; then
        mkdir -p "$cache_dir" 2>/dev/null || { mopidy_cover_fallback; return 0; }
    fi
    # sha256sum already writes its digest as the first whitespace-delimited
    # field. Parse it in Bash rather than starting AWK on every Player poll.
    local hash_output
    hash_output=$(printf '%s' "$track_uri" | sha256sum) || { mopidy_cover_fallback; return 0; }
    key="${hash_output%% *}"
    [[ "$key" =~ ^[0-9a-f]{64}$ ]] || { mopidy_cover_fallback; return 0; }
    marker="$cache_dir/$key.uri"
    stamp="$cache_dir/$key.checked"

    # Cache image URI per track so Player's frequent metadata polling doesn't
    # repeatedly call get_images. Negative results are retried after 30 seconds.
    if [[ -f "$marker" ]]; then
        IFS= read -r art_uri < "$marker" || true
        if [[ -z "$art_uri" ]]; then
            local checked=0
            if mopidy_set_epoch_seconds now; then
                [[ -f "$stamp" ]] && read -r checked < "$stamp"
                if [[ "$checked" =~ ^[0-9]+$ ]] && (( now - checked < 30 )); then
                    mopidy_cover_fallback
                    return 0
                fi
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
        local stamp_now
        if mopidy_set_epoch_seconds stamp_now; then
            printf '%s\n' "$stamp_now" > "$stamp"
        else
            : > "$stamp"
        fi
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
    # Validate an existing cache entry once and carry that result forward.
    # The old flow ran `file` once while checking for a corrupt cache and again
    # after the download branch, even when the same image had just been accepted.
    if [[ -e "$output_path" ]]; then
        if mopidy_is_image_file "$output_path"; then
            output_valid=1
        else
            rm -f "$output_path"
        fi
    fi
    if (( ! output_valid )); then
        failed_at=0
        if mopidy_set_epoch_seconds now; then
            [[ -f "$failed_stamp" ]] && read -r failed_at < "$failed_stamp"
            if [[ "$failed_at" =~ ^[0-9]+$ ]] && (( now - failed_at < 30 )); then
                mopidy_cover_fallback
                return 0
            fi
        fi
        tmp="$output_path.part.$$"
        if curl -fsSL --connect-timeout 1 --max-time 4 "$image_url" -o "$tmp" 2>/dev/null && mopidy_is_image_file "$tmp"; then
            if mv -f -- "$tmp" "$output_path"; then
                rm -f "$failed_stamp"
                # The temporary file was already validated before the atomic
                # rename; don't launch `file` a second time on the same bytes.
                output_valid=1
            else
                rm -f -- "$tmp"
            fi
        else
            rm -f "$tmp"
            local failed_stamp_now
            if mopidy_set_epoch_seconds failed_stamp_now; then
                printf '%s\n' "$failed_stamp_now" > "$failed_stamp"
            else
                : > "$failed_stamp"
            fi
            mopidy_cover_fallback
            return 0
        fi
    fi
    if (( output_valid )) && [[ -s "$output_path" ]]; then
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

    # Parse the batched JSON-RPC response and all current-track fields in a
    # single jq process. NUL delimiters preserve embedded newlines in metadata,
    # unlike line-delimited output, while Bash variables keep the original text.
    local -a metadata_fields=()
    mapfile -d '' -t metadata_fields < <(jq -jr '
        def artist_names:
          (if type == "array" then . else [.] end)
          | map(if type == "object" then (.name // "") elif type == "string" then . else "" end)
          | map(select(type == "string" and length > 0))
          | join(", ");
        def artist_value:
          if type == "object" then (.name // "")
          elif type == "string" then .
          else "" end;
        . as $responses
        | first($responses[] | select(.id == 2) | .result.track) as $track
        | (
            ($track.artists | artist_names) as $track_artists
            | ($track.artist | artist_value) as $track_artist
            | ($track.album.artists | artist_names) as $album_artists
            | ($track.album.artist | artist_value) as $album_artist
            | ($track.performers | artist_names) as $performers
            | if $track_artists != "" then $track_artists
              elif $track_artist != "" then $track_artist
              elif $album_artists != "" then $album_artists
              elif $album_artist != "" then $album_artist
              else $performers end
          ) as $artist
        | [
            (first($responses[] | select(.id == 1) | .result) // ""),
            ((first($responses[] | select(.id == 2) | .result | type) == "object")),
            (first($responses[] | select(.id == 2) | .result.tlid) // ""),
            (first($responses[] | select(.id == 3) | .result) // 0),
            ($track.album.name // ""),
            ($track.album.date // ""),
            ($artist // ""),
            ($track.length // 0),
            ($track.name // ""),
            ($track.uri // ""),
            ($track.album.uri // "")
          ]
        | .[] | (if . == null then "" else tostring end), "\u0000"
    ' <<< "$rpc_data")
    [[ ${#metadata_fields[@]} -eq 11 ]] || return
    state="${metadata_fields[0]}"
    [[ "$state" == "playing" || "$state" == "paused" ]] || return
    [[ "${metadata_fields[1]}" == "true" ]] || return
    local current_tlid="${metadata_fields[2]}"
    trackTime="${metadata_fields[3]}"
    current_album="${metadata_fields[4]}"
    current_album_date="${metadata_fields[5]}"
    current_artist="${metadata_fields[6]}"
    current_length="${metadata_fields[7]}"
    current_title="${metadata_fields[8]}"
    current_track_uri="${metadata_fields[9]}"
    current_album_uri="${metadata_fields[10]}"
    if [[ -z "${current_artist//[[:space:]]/}" ]]; then
        current_artist=$(mopidy_lookup_artist_fallback "$current_track_uri" "$current_tlid")
    fi

    format_album="$current_album_date"
    [[ -n "$current_album" ]] && format_album+=" - $current_album"
    [[ -z "$format_album" ]] && format_album=""
    [[ -z "$current_artist" ]] && current_artist="music"

    # Keep the Player countdown explicit, like mpv and other MPRIS backends.
    # Unknown/zero track lengths have no meaningful remaining-time value.
    time_left=""
    if [[ "$current_length" =~ ^[0-9]+$ && "$trackTime" =~ ^[0-9]+$ ]] && (( current_length > 0 )); then
        local remaining_ms=$((current_length - trackTime))
        (( remaining_ms < 0 )) && remaining_ms=0
        timeFormat_into time_left "$remaining_ms" || time_left=""
        time_left=${time_left##00:}
        [[ -n "$time_left" ]] && time_left="-$time_left"
    fi

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
