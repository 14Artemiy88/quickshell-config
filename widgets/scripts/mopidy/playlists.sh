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

list_playlists() {
    local response
    response="$(rpc 'core.playlists.as_list')" || {
        printf '{"ok":false,"playlists":[],"error":"offline"}\n'
        return 0
    }
    jq -c '
        {
            ok: (any(.error?; . != null) | not),
            playlists: [
                .result[]? |
                {
                    type: (.type // "playlist"),
                    uri: (.uri // ""),
                    name: (.name // "Без названия")
                }
                | select(.uri != "")
            ]
            | sort_by(.name | ascii_downcase)
        }
    ' <<< "$response"
}

playlist_items() {
    local uri="${1:-}"
    [[ -n "$uri" ]] || exit 2

    local response refs_json uris_json detail
    response="$(rpc 'core.playlists.get_items' "$(jq -cn --arg uri "$uri" '{uri:$uri}')")" || {
        printf '{"ok":false,"items":[],"error":"offline"}\n'
        return 0
    }

    refs_json=$(jq -c '[.result[]? | {uri:(.uri // ""), name:(.name // "Без названия"), type:(.type // "track")} | select(.uri != "")]' <<< "$response")
    if [[ "$refs_json" == "[]" ]]; then
        printf '{"ok":true,"items":[]}\n'
        return 0
    fi

    uris_json=$(jq -c '[.[].uri]' <<< "$refs_json")
    detail="$(rpc 'core.library.lookup' "$(jq -cn --argjson uris "$uris_json" '{uris:$uris}')" || true)"

    if [[ -z "$detail" ]]; then
        detail='{"error":"offline"}'
    fi

    jq -cn --argjson refs "$refs_json" --argjson detail "$detail" '
        def track_for($uri):
            ($detail.result[$uri] // [])[0] // {};
        {
            ok: (any($detail.error?; . != null) | not),
            items: [
                $refs[] |
                . as $ref |
                (track_for($ref.uri)) as $track |
                $ref + {
                    name: ($track.name // $ref.name),
                    artist: ([$track.artists[]?.name] | join(", ")),
                    album: ($track.album.name // ""),
                    albumDate: ($track.album.date // ""),
                    duration: ($track.length // 0)
                }
            ]
        }
    '
}


switch_playlist() {
    local uri="${1:-}"
    [[ -n "$uri" ]] || { printf '{"ok":false,"error":"missing_uri"}\n'; return 2; }

    local response uris_json clear_response add_response count
    response="$(rpc 'core.playlists.get_items' "$(jq -cn --arg uri "$uri" '{uri:$uri}')")" || {
        printf '{"ok":false,"error":"offline"}\n'
        return 0
    }
    if jq -e '.error != null or .result == null' >/dev/null 2>&1 <<< "$response"; then
        jq -c '{ok:false,error:(.error.message // "playlist_unavailable")}' <<< "$response"
        return 0
    fi

    uris_json=$(jq -c '[.result[]?.uri?] | map(select(type == "string" and length > 0))' <<< "$response")
    count=$(jq 'length' <<< "$uris_json")

    # Replace the entire current tracklist with the selected playlist.
    clear_response="$(rpc 'core.tracklist.clear' || true)"
    if jq -e '.error != null' >/dev/null 2>&1 <<< "$clear_response"; then
        jq -c '{ok:false,error:(.error.message // "clear_failed")}' <<< "$clear_response"
        return 0
    fi

    if [[ "$uris_json" == "[]" ]]; then
        printf '{"ok":true,"count":0}\n'
        return 0
    fi

    add_response="$(rpc 'core.tracklist.add' "$(jq -cn --argjson uris "$uris_json" '{uris:$uris}')" || true)"
    if jq -e '.error != null' >/dev/null 2>&1 <<< "$add_response"; then
        jq -c '{ok:false,error:(.error.message // "add_failed")}' <<< "$add_response"
        return 0
    fi

    jq -cn --argjson count "$count" '{ok:true,count:$count}'
}

create_playlist() {
    local name="${1:-}"
    [[ -n "$name" ]] || { printf '{"ok":false,"error":"empty_name"}\n'; return 0; }
    local response
    response="$(rpc 'core.playlists.create' "$(jq -cn --arg name "$name" '{name:$name}')")" || {
        printf '{"ok":false,"error":"offline"}\n'
        return 0
    }
    jq -c '{ok:(.error? == null), playlist:(.result // null), error:(.error.message // null)}' <<< "$response"
}

lookup_playlist() {
    local uri="${1:-}"
    [[ -n "$uri" ]] || { printf '{"ok":false,"error":"missing_uri"}\n'; return 0; }
    local response
    response="$(rpc 'core.playlists.lookup' "$(jq -cn --arg uri "$uri" '{uri:$uri}')")" || {
        printf '{"ok":false,"error":"offline"}\n'
        return 0
    }
    jq -c '{ok:(.error? == null and .result != null), playlist:(.result // null), error:(.error.message // null)}' <<< "$response"
}

rename_playlist() {
    local uri="${1:-}" name="${2:-}"
    [[ -n "$uri" && -n "$name" ]] || { printf '{"ok":false,"error":"missing_argument"}\n'; return 0; }
    local response lookup model saved
    lookup="$(rpc 'core.playlists.lookup' "$(jq -cn --arg uri "$uri" '{uri:$uri}')")" || {
        printf '{"ok":false,"error":"offline"}\n'
        return 0
    }
    model="$(jq -c --arg name "$name" 'if (.result // null) == null then empty else .result | .name=$name end' <<< "$lookup")"
    [[ -n "$model" ]] || { printf '{"ok":false,"error":"not_found"}\n'; return 0; }
    saved="$(rpc 'core.playlists.save' "$(jq -cn --argjson playlist "$model" '{playlist:$playlist}')")" || {
        printf '{"ok":false,"error":"offline"}\n'
        return 0
    }
    jq -c '{ok:(.error? == null and .result != null), playlist:(.result // null), error:(.error.message // null)}' <<< "$saved"
}


move_playlist_item() {
    local uri="${1:-}" index="${2:-}" new_index="${3:-}"
    [[ -n "$uri" && "$index" =~ ^[0-9]+$ && "$new_index" =~ ^[0-9]+$ ]] || { printf '{"ok":false,"error":"missing_argument"}\n'; return 0; }

    local lookup model count saved
    lookup="$(rpc 'core.playlists.lookup' "$(jq -cn --arg uri "$uri" '{uri:$uri}')")" || {
        printf '{"ok":false,"error":"offline"}\n'
        return 0
    }

    count=$(jq -r '(.result.tracks // []) | length' <<< "$lookup")
    if [[ "$count" -eq 0 ]]; then
        printf '{"ok":false,"error":"playlist_empty"}\n'
        return 0
    fi
    if (( index >= count || new_index >= count )); then
        printf '{"ok":false,"error":"item_not_found"}\n'
        return 0
    fi
    if (( index == new_index )); then
        printf '{"ok":true}\n'
        return 0
    fi

    model="$(jq -c --argjson index "$index" --argjson new_index "$new_index" '
        .result as $playlist
        | if $playlist == null then empty
          else
            $playlist
            | .tracks = (
                .tracks // []
                | . as $tracks
                | $tracks[$index] as $moved
                | [ $tracks | to_entries[] | select(.key != $index) | .value ] as $rest
                | ($rest[:$new_index] + [$moved] + $rest[$new_index:])
              )
          end
    ' <<< "$lookup")"
    [[ -n "$model" ]] || { printf '{"ok":false,"error":"playlist_not_found"}\n'; return 0; }

    saved="$(rpc 'core.playlists.save' "$(jq -cn --argjson playlist "$model" '{playlist:$playlist}')")" || {
        printf '{"ok":false,"error":"offline"}\n'
        return 0
    }
    if jq -e '.error != null or .result == null' >/dev/null 2>&1 <<< "$saved"; then
        jq -c '{ok:false,error:(.error.message // "playlist_save_failed")}' <<< "$saved"
        return 0
    fi

    jq -cn '{ok:true}'
}

delete_playlist() {
    local uri="${1:-}"
    [[ -n "$uri" ]] || { printf '{"ok":false,"error":"missing_uri"}\n'; return 0; }
    local response
    response="$(rpc 'core.playlists.delete' "$(jq -cn --arg uri "$uri" '{uri:$uri}')")" || {
        printf '{"ok":false,"error":"offline"}\n'
        return 0
    }
    jq -c '{ok:(.error? == null and (.result // false) == true), deleted:(.result // false), error:(.error.message // null)}' <<< "$response"
}

remove_playlist_item() {
    local uri="${1:-}" index="${2:-}"
    [[ -n "$uri" && "$index" =~ ^[0-9]+$ ]] || { printf '{"ok":false,"error":"missing_argument"}\n'; return 0; }

    local lookup model tracks_count saved
    lookup="$(rpc 'core.playlists.lookup' "$(jq -cn --arg uri "$uri" '{uri:$uri}')")" || {
        printf '{"ok":false,"error":"offline"}\n'
        return 0
    }

    tracks_count=$(jq -r '(.result.tracks // []) | length' <<< "$lookup")
    if [[ "$tracks_count" -eq 0 ]]; then
        printf '{"ok":false,"error":"playlist_empty"}\n'
        return 0
    fi
    if (( index >= tracks_count )); then
        printf '{"ok":false,"error":"item_not_found"}\n'
        return 0
    fi

    model="$(jq -c --argjson index "$index" '
        .result as $playlist
        | if $playlist == null then empty
          else
            $playlist
            | .tracks = [(.tracks // []) | to_entries[] | select(.key != $index) | .value]
          end
    ' <<< "$lookup")"
    [[ -n "$model" ]] || { printf '{"ok":false,"error":"playlist_not_found"}\n'; return 0; }

    saved="$(rpc 'core.playlists.save' "$(jq -cn --argjson playlist "$model" '{playlist:$playlist}')")" || {
        printf '{"ok":false,"error":"offline"}\n'
        return 0
    }
    if jq -e '.error != null or .result == null' >/dev/null 2>&1 <<< "$saved"; then
        jq -c '{ok:false,error:(.error.message // "playlist_save_failed")}' <<< "$saved"
        return 0
    fi

    jq -cn '{ok:true}'
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

add_uri_list_to_playlist() {
    local playlist_uri="${1:-}"
    shift || true
    (( $# > 0 )) || { printf '{"ok":false,"error":"no_tracks"}\n'; return 0; }

    local uris_json lookup detail tracks_json model saved count
    uris_json=$(printf '%s\n' "$@" | jq -Rsc 'split("\n") | map(select(length > 0)) | unique')

    lookup="$(rpc 'core.playlists.lookup' "$(jq -cn --arg uri "$playlist_uri" '{uri:$uri}')" || true)"
    model="$(jq -c '.result // empty' <<< "$lookup")"
    if [[ -z "$model" || "$model" == "null" ]]; then
        printf '{"ok":false,"error":"playlist_not_found"}\n'
        return 0
    fi

    detail="$(rpc 'core.library.lookup' "$(jq -cn --argjson uris "$uris_json" '{uris:$uris}')" || true)"
    if [[ -z "$detail" ]] || jq -e '.error != null' >/dev/null 2>&1 <<< "$detail"; then
        printf '{"ok":false,"error":"track_lookup_failed"}\n'
        return 0
    fi

    tracks_json=$(jq -c --argjson uris "$uris_json" '[ $uris[] as $u | (.result[$u] // [])[]? ]' <<< "$detail")
    count=$(jq 'length' <<< "$tracks_json")
    if (( count == 0 )); then
        printf '{"ok":false,"error":"tracks_not_found"}\n'
        return 0
    fi

    model=$(jq -c --argjson tracks "$tracks_json" '.tracks = ((.tracks // []) + $tracks)' <<< "$model")
    saved="$(rpc 'core.playlists.save' "$(jq -cn --argjson playlist "$model" '{playlist:$playlist}')" || true)"
    if [[ -z "$saved" ]] || jq -e '.error != null or .result == null' >/dev/null 2>&1 <<< "$saved"; then
        jq -c '{ok:false,error:(.error.message // "playlist_save_failed")}' <<< "${saved:-{\"error\":{\"message\":\"playlist_save_failed\"}}}"
        return 0
    fi

    jq -cn --argjson count "$count" '{ok:true,count:$count}'
}

add_to_playlist() {
    local playlist_uri="${1:-}" track_uri="${2:-}"
    [[ -n "$playlist_uri" && -n "$track_uri" ]] || { printf '{"ok":false,"error":"missing_argument"}\n'; return 0; }
    add_uri_list_to_playlist "$playlist_uri" "$track_uri"
}

add_folder_to_playlist() {
    local playlist_uri="${1:-}" folder_uri="${2:-}"
    [[ -n "$playlist_uri" && -n "$folder_uri" ]] || { printf '{"ok":false,"error":"missing_argument"}\n'; return 0; }
    local tracks_json
    tracks_json=$(collect_folder_tracks "$folder_uri" | jq -Rsc 'split("\n") | map(select(length > 0)) | unique')
    if [[ "$tracks_json" == "[]" ]]; then
        printf '{"ok":false,"error":"folder_empty"}\n'
        return 0
    fi
    mapfile -t tracks < <(jq -r '.[]' <<< "$tracks_json")
    add_uri_list_to_playlist "$playlist_uri" "${tracks[@]}"
}

add_uris() {
    (( $# > 0 )) || exit 0
    local uris_json
    uris_json=$(printf '%s\n' "$@" | jq -Rsc 'split("\n") | map(select(length > 0))')
    rpc 'core.tracklist.add' "$(jq -cn --argjson uris "$uris_json" '{uris:$uris}')" >/dev/null
}

add_playlist() {
    local uri="${1:-}"
    [[ -n "$uri" ]] || exit 2
    local response uris_json
    response="$(rpc 'core.playlists.get_items' "$(jq -cn --arg uri "$uri" '{uri:$uri}')")" || exit 0
    uris_json=$(jq -c '[.result[]?.uri?] | map(select(type == "string" and length > 0))' <<< "$response")
    [[ "$uris_json" != "[]" ]] || exit 0
    rpc 'core.tracklist.add' "$(jq -cn --argjson uris "$uris_json" '{uris:$uris}')" >/dev/null
}

case "${1:-list}" in
    list)
        list_playlists
        ;;
    items)
        playlist_items "${2:-}"
        ;;
    add)
        shift
        add_uris "$@"
        ;;
    add_track)
        add_uris "${2:-}"
        ;;
    add_playlist)
        add_playlist "${2:-}"
        ;;
    add_to_playlist)
        add_to_playlist "${2:-}" "${3:-}"
        ;;
    add_folder_to_playlist)
        add_folder_to_playlist "${2:-}" "${3:-}"
        ;;
    switch_playlist)
        switch_playlist "${2:-}"
        ;;
    create)
        create_playlist "${2:-}"
        ;;
    rename)
        rename_playlist "${2:-}" "${3:-}"
        ;;
    delete)
        delete_playlist "${2:-}"
        ;;
    remove_item)
        remove_playlist_item "${2:-}" "${3:-}"
        ;;
    move_item)
        move_playlist_item "${2:-}" "${3:-}" "${4:-}"
        ;;
    lookup)
        lookup_playlist "${2:-}"
        ;;
    *)
        printf 'usage: %s {list|items|add|add_track|add_playlist|add_to_playlist|add_folder_to_playlist|switch_playlist|create|rename|delete|remove_item|move_item|lookup} [args...]\n' "$0" >&2
        exit 2
        ;;
esac
