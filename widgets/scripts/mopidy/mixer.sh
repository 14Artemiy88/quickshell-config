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

get_mixer() {
    local volume_response mute_response volume mute
    volume_response=$(rpc 'core.mixer.get_volume' || true)
    mute_response=$(rpc 'core.mixer.get_mute' || true)

    volume=$(printf '%s\n' "$volume_response" | jq -r 'if .error or .result == null then empty else .result end' 2>/dev/null || true)
    mute=$(printf '%s\n' "$mute_response" | jq -r 'if .error or .result == null then empty else .result end' 2>/dev/null || true)

    if [[ -z "$volume" && -z "$mute" ]]; then
        printf '{"ok":false,"volume":null,"mute":null}\n'
        return 0
    fi

    if [[ ! "$volume" =~ ^[0-9]+$ ]]; then
        volume="null"
    fi
    if [[ "$mute" != "true" && "$mute" != "false" ]]; then
        mute="null"
    fi

    jq -cn --argjson volume "$volume" --argjson mute "$mute" '{ok:true,volume:$volume,mute:$mute}'
}

set_volume() {
    local value="${1:-}"
    if [[ ! "$value" =~ ^[0-9]+$ ]]; then
        printf '{"ok":false,"error":"invalid-volume"}\n'
        return 2
    fi
    value=$(( value < 0 ? 0 : value > 100 ? 100 : value ))
    local response
    response=$(rpc 'core.mixer.set_volume' "$(jq -cn --argjson volume "$value" '{volume:$volume}')" || true)
    jq -c '{ok:(.error == null), result:(.result // null)}' <<<"$response" 2>/dev/null || printf '{"ok":false}\n'
}

set_mute() {
    local value="${1:-toggle}"
    if [[ "$value" == "toggle" ]]; then
        local current
        current=$(rpc 'core.mixer.get_mute' | jq -r '.result // false' 2>/dev/null || printf 'false')
        [[ "$current" == "true" ]] && value=false || value=true
    fi
    if [[ "$value" != "true" && "$value" != "false" ]]; then
        printf '{"ok":false,"error":"invalid-mute"}\n'
        return 2
    fi
    local response
    response=$(rpc 'core.mixer.set_mute' "$(jq -cn --argjson mute "$value" '{mute:$mute}')" || true)
    jq -c '{ok:(.error == null), result:(.result // null)}' <<<"$response" 2>/dev/null || printf '{"ok":false}\n'
}

case "${1:-get}" in
    get) get_mixer ;;
    set) set_volume "${2:-}" ;;
    mute) set_mute "${2:-toggle}" ;;
    *) echo "Usage: $0 {get|set <0-100>|mute [true|false|toggle]}" >&2; exit 1 ;;
esac
