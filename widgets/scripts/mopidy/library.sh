#!/bin/bash
set -euo pipefail

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
    local params response

    if [[ -n "$uri" ]]; then
        params=$(jq -cn --arg uri "$uri" '{uri:$uri}')
    else
        params='{"uri":null}'
    fi

    response=$(rpc 'core.library.browse' "$params") || {
        printf '{"ok":false,"entries":[],"error":"offline"}\n'
        return 0
    }

    jq -c '
        {
            ok: (any(.error?; . != null) | not),
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
    *)
        printf 'usage: %s {search|browse|add|add_folder} [query|uri]\n' "$0" >&2
        exit 2
        ;;
esac
