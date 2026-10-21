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

bool_result() {
    printf '%s\n' "$1" | jq -r 'if .error or .result == null then empty else (.result|tostring) end' 2>/dev/null || true
}

get_state() {
    local random repeat single
    random=$(bool_result "$(rpc 'core.tracklist.get_random' || true)")
    repeat=$(bool_result "$(rpc 'core.tracklist.get_repeat' || true)")
    single=$(bool_result "$(rpc 'core.tracklist.get_single' || true)")
    if [[ -z "$random" || -z "$repeat" || -z "$single" ]]; then
        printf '{"ok":false,"random":false,"repeat":false,"single":false}\n'
        return
    fi
    jq -cn --argjson random "$random" --argjson repeat "$repeat" --argjson single "$single" \
        '{ok:true,random:$random,repeat:$repeat,single:$single}'
}

set_random() {
    local value="${1:-false}"
    rpc 'core.tracklist.set_random' "$(jq -cn --argjson value "$value" '{value:$value}')" >/dev/null
}

set_repeat_mode() {
    local mode="${1:-0}"
    case "$mode" in
        0) rpc 'core.tracklist.set_single' '{"value":false}' >/dev/null; rpc 'core.tracklist.set_repeat' '{"value":false}' >/dev/null ;;
        1) rpc 'core.tracklist.set_single' '{"value":false}' >/dev/null; rpc 'core.tracklist.set_repeat' '{"value":true}' >/dev/null ;;
        2) rpc 'core.tracklist.set_repeat' '{"value":true}' >/dev/null; rpc 'core.tracklist.set_single' '{"value":true}' >/dev/null ;;
        *) exit 2 ;;
    esac
}

case "${1:-state}" in
    state) get_state ;;
    random) set_random "${2:-false}" ;;
    repeat) set_repeat_mode "${2:-0}" ;;
    *) exit 2 ;;
esac
