#!/bin/bash

# This file is sourced on each weather poll. Its parent path is only used to
# source the sibling env file, so it doesn't need canonicalization via dirname.
WEATHER_COMMON_PATH="${BASH_SOURCE[0]}"
if [[ "$WEATHER_COMMON_PATH" == */* ]]; then
    WEATHER_SCRIPT_DIR="${WEATHER_COMMON_PATH%/*}/.."
else
    WEATHER_SCRIPT_DIR=".."
fi
source "$WEATHER_SCRIPT_DIR/env"
unset WEATHER_COMMON_PATH

declare -r WEATHER_CACHE_DIR="${WEATHER_CACHE_DIR:-$QS_CACHE_DIR/weather}"
declare -r WEATHER_CACHE_TTL="${WEATHER_CACHE_TTL:-600}"
declare -r WEATHER_ERROR_RETRY_TTL="${WEATHER_ERROR_RETRY_TTL:-30}"
declare -r WEATHER_CURL_CONNECT_TIMEOUT="${WEATHER_CURL_CONNECT_TIMEOUT:-5}"
declare -r WEATHER_CURL_MAX_TIME="${WEATHER_CURL_MAX_TIME:-10}"

weather_read_token() {
    local secrets_file="$QS_CONFIG_DIR/secrets.json"
    jq -r 'if (.weatherToken | type) == "string" then .weatherToken else "" end' "$secrets_file" 2>/dev/null || true
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
    # Bash 5+ exposes the current epoch second without spawning `date` on
    # every cache hit. Keep the external fallback for older Bash versions.
    if [[ "${EPOCHSECONDS+x}" == x && "$EPOCHSECONDS" =~ ^[0-9]+$ ]]; then
        now=$EPOCHSECONDS
    else
        now=$(date +%s) || return 1
    fi
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
    local payload
    [[ -s "$cache_file" ]] || return 1
    # Read the cache with Bash's redirection shortcut instead of a `cat`
    # process. Command substitution keeps the same trailing-newline behavior.
    payload=$(<"$cache_file") || return 1
    weather_payload_usable "$payload" || return 1
    printf '%s\n' "$payload"
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
    # The caller passes a payload already validated by weather_gismeteo_fetch.
    # Avoid starting `cat` and another `jq` merely to re-parse the same bytes;
    # the checked printf plus atomic rename are sufficient for safe publication.
    if [[ ! -s "$tmp_file" ]]; then
        rm -f -- "$tmp_file"
        return 1
    fi
    # GNU/BSD mktemp creates this file with mode 0600; chmod would only add
    # an external process on every weather refresh without tightening it.
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
    # mktemp already sets the attempt marker to 0600. Keep the atomic rename
    # and avoid an otherwise redundant chmod process on each API attempt.
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
