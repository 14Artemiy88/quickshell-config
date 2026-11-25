#!/bin/bash
set -euo pipefail

SCRIPT_DIR="${BASH_SOURCE[0]%/*}"
[[ "$SCRIPT_DIR" != "${BASH_SOURCE[0]}" ]] || SCRIPT_DIR=.
# Reuse the exact artwork resolver already used by the Player. This covers both
# Mopidy backends which expose images through get_images and file:// tracks whose
# album art is discovered beside the media file on disk.
source "$SCRIPT_DIR/../player.d/common.sh"
source "$SCRIPT_DIR/player_backend.sh"
MOPIDY_RPC_URL="${MOPIDY_RPC_URL:-http://localhost:6680/mopidy/rpc}"

rpc() {
    local method="$1"
    local params="{}"
    [[ -n "${2:-}" ]] && params="$2"

    curl -sS --connect-timeout 1 --max-time 3 \
        -H 'Content-Type: application/json' \
        -d "$(jq -cn --argjson params "$params" --arg method "$method" '{jsonrpc:"2.0",id:1,method:$method,params:$params}')" \
        "$MOPIDY_RPC_URL" 2>/dev/null
}

# Resolve artwork for the folder currently open in the browser by using the
# same function as the live Player. This matters for Mopidy-File: that backend
# does not implement get_images, while the Player can still show covers by
# scanning conventional image files beside the track (cover.jpg, folder.jpg,
# front.png, etc.). For image-capable backends the same resolver uses Mopidy's
# get_images lookup and its validated on-disk cache.
mopidy_folder_cover() {
    local folder_uri="${1:-}" browse_response="${2:-}" track_uris lookup_params lookup_json album_map first_track album_uri cover_path
    [[ -n "$folder_uri" && -n "$browse_response" ]] || return 0

    track_uris=$(jq -c '[.result[]? | select(((.type // "") | ascii_downcase) == "track") | .uri | select(type == "string" and length > 0)] | .[:5]' <<< "$browse_response" 2>/dev/null) || track_uris='[]'
    first_track=$(jq -r '.[0] // ""' <<< "$track_uris" 2>/dev/null) || first_track=""
    [[ -n "$first_track" ]] || return 0

    # Resolve Album.uri exactly as Player does from Track metadata. File-based
    # tracks may not be resolvable through lookup; their adjacent cover search
    # still works because mopidy_cover_for_track handles file:// before RPC.
    lookup_params=$(jq -cn --argjson tracks "$track_uris" '{uris:$tracks}') || lookup_params=''
    album_map='{}'
    if [[ -n "$lookup_params" ]]; then
        lookup_json=$(rpc 'core.library.lookup' "$lookup_params") || lookup_json='{}'
        album_map=$(jq -c --argjson tracks "$track_uris" '
            (.result // {}) as $lookup
            | reduce $tracks[] as $track ({ };
                .[$track] = ([($lookup[$track] // [])[]? | .album.uri? | select(type == "string" and length > 0)][0] // "")
              )
        ' <<< "$lookup_json" 2>/dev/null) || album_map='{}'
    fi
    album_uri=$(jq -r '[.[] | select(type == "string" and length > 0)][0] // ""' <<< "$album_map" 2>/dev/null) || album_uri=""

    # One invocation of the Player's resolver is enough for an album folder:
    # it checks adjacent local cover files first, then asks Mopidy for images
    # by the same Track + Album URIs used by the visible Player, and reuses the
    # exact same validated cache. Avoid five repeated RPC/download attempts.
    cover_path=$(mopidy_cover_for_track "$first_track" "$album_uri") || cover_path=""
    # The Player's compatibility fallback is intentionally not artwork;
    # don't display its placeholder in the folder header.
    if [[ -n "$cover_path" && "$cover_path" != "$DEFAULT_IMG" && "$cover_path" != */album_cover.png && -s "$cover_path" ]]; then
        printf '%s\n' "$cover_path"
    fi
}

folder_cover() {
    local uri="${1:-}" params response cover=""
    [[ -n "$uri" ]] || return 0
    params=$(jq -cn --arg uri "$uri" '{uri:$uri}') || return 0
    response=$(rpc 'core.library.browse' "$params") || response='{}'
    if jq -e 'any(.error?; . != null)' <<< "$response" >/dev/null 2>&1; then
        return 0
    fi
    cover=$(mopidy_folder_cover "$uri" "$response") || cover=""
    [[ -n "$cover" && -s "$cover" ]] && printf '%s\n' "$cover"
}

search_library() {
    local query="${1:-}"
    query="${query#${query%%[![:space:]]*}}"
    query="${query%${query##*[![:space:]]}}"

    if [[ -z "$query" ]]; then
        printf '{"ok":true,"results":[]}\n'
        return 0
    fi

    local params response
    params=$(jq -cn --arg q "$query" '{query:{any:[$q]},exact:false}')
    response=$(rpc 'core.library.search' "$params") || {
        printf '{"ok":false,"results":[],"error":"offline"}\n'
        return 0
    }

    jq -c '
        {
            ok: (any(.error?; . != null) | not),
            results: [
                .result[]?.tracks[]? |
                {
                    uri: (.uri // ""),
                    name: (.name // "Без названия"),
                    artist: ([.artists[]?.name] | join(", ")),
                    album: (.album.name // ""),
                    albumDate: (.album.date // ""),
                    duration: (.length // 0)
                }
                | select(.uri != "")
            ]
            | unique_by(.uri)
            | .[:100]
        }
    ' <<< "$response"
}

add_track() {
    local uri="${1:-}"
    [[ -n "$uri" ]] || exit 2
    rpc 'core.tracklist.add' "$(jq -cn --arg uri "$uri" '{uris:[$uri]}')" >/dev/null
}

collect_folder_tracks() {
    local uri="${1:-}"
    [[ -n "$uri" ]] || return 0

    local params response entry_type entry_uri
    params=$(jq -cn --arg uri "$uri" '{uri:$uri}')
    response=$(rpc 'core.library.browse' "$params") || return 0

    while IFS=$'\t' read -r entry_type entry_uri; do
        [[ -n "$entry_uri" ]] || continue
        if [[ "$entry_type" == "track" ]]; then
            printf '%s\n' "$entry_uri"
        elif [[ "$entry_type" == "directory" ]]; then
            collect_folder_tracks "$entry_uri"
        fi
    done < <(jq -r '.result[]? | [(.type // ""), (.uri // "")] | @tsv' <<< "$response")
}

add_folder() {
    local uri="${1:-}"
    [[ -n "$uri" ]] || exit 2

    local tracks_json
    tracks_json=$(collect_folder_tracks "$uri" | jq -R -s 'split("\n") | map(select(length > 0))')
    if [[ "$tracks_json" == "[]" ]]; then
        exit 0
    fi

    rpc 'core.tracklist.add' "$(jq -cn --argjson uris "$tracks_json" '{uris:$uris}')" >/dev/null
}

browse_library() {
    local uri="${1:-}"
    local params response folder_cover=""

    if [[ -n "$uri" ]]; then
        params=$(jq -cn --arg uri "$uri" '{uri:$uri}')
    else
        params='{"uri":null}'
    fi

    response=$(rpc 'core.library.browse' "$params") || {
        printf '{"ok":false,"entries":[],"error":"offline"}\n'
        return 0
    }

    if [[ -n "$uri" ]] && ! jq -e 'any(.error?; . != null)' <<< "$response" >/dev/null 2>&1; then
        folder_cover=$(mopidy_folder_cover "$uri" "$response") || folder_cover=""
    fi

    jq -c --arg folderCover "$folder_cover" '
        {
            ok: (any(.error?; . != null) | not),
            folderCover: $folderCover,
            entries: [
                .result[]? |
                select((.type // "") == "directory" or (.type // "") == "track") |
                {
                    type: (.type // ""),
                    uri: (.uri // ""),
                    name: (.name // "Без названия")
                }
                | select(.uri != "")
            ]
            | sort_by(if .type == "directory" then 0 else 1 end, (.name | ascii_downcase))
        }
    ' <<< "$response"
}

case "${1:-search}" in
    search)
        search_library "${2:-}"
        ;;
    add)
        add_track "${2:-}"
        ;;
    add_folder)
        add_folder "${2:-}"
        ;;
    browse)
        browse_library "${2:-}"
        ;;
    folder_cover)
        folder_cover "${2:-}"
        ;;
    *)
        printf 'usage: %s {search|browse|folder_cover|add|add_folder} [query|uri]\n' "$0" >&2
        exit 2
        ;;
esac
