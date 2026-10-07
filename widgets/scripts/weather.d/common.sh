#!/bin/bash

WEATHER_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$WEATHER_SCRIPT_DIR/env"

declare -r WEATHER_CACHE_DIR="${WEATHER_CACHE_DIR:-/tmp/weather_cache}"
declare -r WEATHER_CACHE_TTL="${WEATHER_CACHE_TTL:-600}"
declare -r WEATHER_CURL_CONNECT_TIMEOUT="${WEATHER_CURL_CONNECT_TIMEOUT:-5}"
declare -r WEATHER_CURL_MAX_TIME="${WEATHER_CURL_MAX_TIME:-10}"

weather_read_token() {
    local settings_file="$QS_CONFIG_DIR/settings.json"
    jq -r '.weatherToken // ""' "$settings_file" 2>/dev/null || true
}

weather_cache_file() {
    local cache_name="$1"
    local params="$2"
    printf '%s/%s_%s.json\n' \
        "$WEATHER_CACHE_DIR" \
        "$cache_name" \
        "${params//[^a-zA-Z0-9]/_}"
}

weather_cache_valid() {
    local cache_file="$1"
    [[ -f "$cache_file" ]] || return 1
    local age=$(( $(date +%s) - $(stat -c %Y "$cache_file") ))
    (( age < WEATHER_CACHE_TTL ))
}

weather_cache_read() {
    local cache_file="$1"
    cat "$cache_file"
}

weather_cache_write() {
    local cache_file="$1"
    local payload="$2"
    local tmp_file
    tmp_file=$(mktemp "${cache_file}.XXXXXX") || return 1
    printf '%s\n' "$payload" > "$tmp_file" || {
        rm -f "$tmp_file"
        return 1
    }
    if ! jq -e '((type == "object") or (type == "array"))' "$tmp_file" >/dev/null 2>&1; then
        rm -f "$tmp_file"
        return 1
    fi
    mv -f "$tmp_file" "$cache_file"
}

weather_require_token() {
    local token
    token=$(weather_read_token)
    if [[ -z "$token" ]]; then
        echo "Ошибка: токен Gismeteo не задан" >&2
        return 1
    fi
    printf '%s' "$token"
}
