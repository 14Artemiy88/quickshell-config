#!/bin/bash

WEATHER_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$WEATHER_SCRIPT_DIR/env"

declare -r WEATHER_CACHE_DIR="${WEATHER_CACHE_DIR:-$QS_CACHE_DIR/weather}"
declare -r WEATHER_CACHE_TTL="${WEATHER_CACHE_TTL:-600}"
declare -r WEATHER_ERROR_RETRY_TTL="${WEATHER_ERROR_RETRY_TTL:-30}"
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
    local cache_file="$1" modified now age
    [[ -f "$cache_file" ]] || return 1
    modified=$(stat -c %Y -- "$cache_file" 2>/dev/null) || return 1
    [[ "$modified" =~ ^[0-9]+$ ]] || return 1
    now=$(date +%s) || return 1
    age=$((now - modified))
    # A future mtime can occur after clock adjustments; don't treat it as a
    # valid fresh cache indefinitely.
    (( age >= 0 && age < WEATHER_CACHE_TTL ))
}

weather_payload_usable() {
    local payload="$1"
    jq -e 'if type == "object" then length > 0 elif type == "array" then length > 0 else false end' \
        >/dev/null 2>&1 <<< "$payload"
}

weather_cache_read_usable() {
    local cache_file="$1"
    [[ -s "$cache_file" ]] || return 1
    # Parse the cache file directly instead of spawning `cat` and then feeding
    # the result to jq. Slurp mode also rejects multiple JSON documents; emit
    # one compact object/array only when its top-level payload is usable.
    jq -cse '
        if length == 1 then
            .[0] | if (type == "object" or type == "array") and length > 0
                   then . else empty end
        else empty end
    ' -- "$cache_file" 2>/dev/null
}

weather_cache_write() {
    local cache_file="$1"
    local payload="$2"
    local tmp_file
    tmp_file=$(mktemp "${cache_file}.XXXXXX") || return 1
    if ! printf '%s\n' "$payload" > "$tmp_file"; then
        rm -f -- "$tmp_file"
        return 1
    fi
    if ! weather_payload_usable "$(cat -- "$tmp_file")"; then
        rm -f -- "$tmp_file"
        return 1
    fi
    chmod 600 "$tmp_file" 2>/dev/null || true
    mv -f -- "$tmp_file" "$cache_file" || {
        rm -f -- "$tmp_file"
        return 1
    }
}

weather_attempt_recent() {
    local attempt_file="$1" now="$2" modified age
    [[ -f "$attempt_file" ]] || return 1
    read -r modified < "$attempt_file" || return 1
    [[ "$modified" =~ ^[0-9]+$ ]] || return 1
    age=$((now - modified))
    (( age >= 0 && age < WEATHER_ERROR_RETRY_TTL ))
}

weather_mark_attempt() {
    local attempt_file="$1" now="$2" tmp_file
    tmp_file=$(mktemp "${attempt_file}.XXXXXX") || return 1
    if ! printf '%s\n' "$now" > "$tmp_file"; then
        rm -f -- "$tmp_file"
        return 1
    fi
    chmod 600 "$tmp_file" 2>/dev/null || true
    mv -f -- "$tmp_file" "$attempt_file" || {
        rm -f -- "$tmp_file"
        return 1
    }
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
