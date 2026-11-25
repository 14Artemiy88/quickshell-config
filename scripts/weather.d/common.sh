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

# These values are used in Bash arithmetic expressions below. Never let raw
# environment strings reach arithmetic evaluation: Bash recursively evaluates
# variable contents there, including command substitutions in malformed input.
_weather_normalize_duration() {
    local raw="$1" fallback="$2" max="$3"
    if [[ "$raw" =~ ^[0-9]{1,10}$ ]]; then
        WEATHER_NORMALIZED_DURATION=$((10#$raw))
        (( WEATHER_NORMALIZED_DURATION <= max )) || WEATHER_NORMALIZED_DURATION="$fallback"
    else
        WEATHER_NORMALIZED_DURATION="$fallback"
    fi
}
_weather_normalize_duration "${WEATHER_CACHE_TTL:-600}" 600 2147483647
declare -r WEATHER_CACHE_TTL="$WEATHER_NORMALIZED_DURATION"
_weather_normalize_duration "${WEATHER_ERROR_RETRY_TTL:-30}" 30 2147483647
declare -r WEATHER_ERROR_RETRY_TTL="$WEATHER_NORMALIZED_DURATION"
unset WEATHER_NORMALIZED_DURATION
unset -f _weather_normalize_duration

# curl timeout values are passed as option arguments, not evaluated by Bash,
# but malformed values can disable timeouts or make every poll fail. Accept
# bounded positive decimal seconds only, normalize leading/trailing zeroes,
# and fall back before constructing the curl command.
_weather_normalize_curl_timeout() {
    local raw="$1" fallback="$2" whole fraction
    WEATHER_NORMALIZED_CURL_TIMEOUT="$fallback"
    if [[ ! "$raw" =~ ^([0-9]{1,10})([.]([0-9]{1,3}))?$ ]]; then
        return 0
    fi
    whole="${BASH_REMATCH[1]}"
    fraction="${BASH_REMATCH[3]:-}"
    while [[ ${#whole} -gt 1 && "${whole:0:1}" == "0" ]]; do
        whole="${whole:1}"
    done
    # Numeric comparison is safe only after the strict decimal validation and
    # leading-zero normalization above. Keep curl bounded to 120 seconds.
    (( 10#$whole <= 120 )) || return 0
    if (( 10#$whole == 120 )) && [[ "$fraction" =~ [1-9] ]]; then
        return 0
    fi
    # A zero timeout disables curl's timeout. Require a strictly positive
    # value, but retain sub-second decimal values for intentional tuning.
    if (( 10#$whole == 0 )) && [[ ! "$fraction" =~ [1-9] ]]; then
        return 0
    fi
    while [[ "$fraction" == *0 ]]; do fraction="${fraction%0}"; done
    if [[ -n "$fraction" ]]; then
        WEATHER_NORMALIZED_CURL_TIMEOUT="$whole.$fraction"
    else
        WEATHER_NORMALIZED_CURL_TIMEOUT="$whole"
    fi
}
_weather_normalize_curl_timeout "${WEATHER_CURL_CONNECT_TIMEOUT:-5}" 5
WEATHER_CURL_CONNECT_TIMEOUT="$WEATHER_NORMALIZED_CURL_TIMEOUT"
_weather_normalize_curl_timeout "${WEATHER_CURL_MAX_TIME:-10}" 10
WEATHER_CURL_MAX_TIME="$WEATHER_NORMALIZED_CURL_TIMEOUT"
unset WEATHER_NORMALIZED_CURL_TIMEOUT
unset -f _weather_normalize_curl_timeout
declare -r WEATHER_CURL_CONNECT_TIMEOUT WEATHER_CURL_MAX_TIME

weather_read_token() {
    local secrets_file="$QS_CONFIG_DIR/secrets.json"
    # Read the entire secrets file as one JSON document before emitting any
    # token. Without --slurp, jq can print a valid first document and then
    # fail on trailing garbage; `|| true` would otherwise hide that parse
    # failure and let the partial token reach curl. Slurping also rejects
    # concatenated documents instead of choosing one implicitly.
    # HTTP header values must not contain control characters. Reject them in
    # jq before raw output so escaped NUL/newline bytes never enter a Bash
    # command substitution (which cannot represent NUL safely).
    jq -rs 'if length == 1 and (.[0] | type) == "object"
            then (.[0].weatherToken
                  | if type == "string" and (explode | all(. >= 32 and . != 127))
                    then . else "" end)
            else "" end' \
        "$secrets_file" 2>/dev/null || true
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

# Endpoint-specific cache shape validation prevents a successful JSON parse
# from treating a current-weather object as a forecast array (or vice versa).
# The optional `any` mode remains available to generic cache utilities/tests.
weather_payload_usable() {
    local payload="$1"
    local expected_type="${2:-any}"
    case "$expected_type" in
        any)
            # Slurp first so concatenated JSON values cannot pass based only on
            # the shape of the final document.
            jq -es 'length == 1 and (.[0] | (type == "object" or type == "array") and length > 0)' \
                >/dev/null 2>&1 <<< "$payload"
            ;;
        object|array)
            jq -es --arg expected_type "$expected_type" \
                'length == 1 and (.[0] | type == $expected_type and length > 0)' \
                >/dev/null 2>&1 <<< "$payload"
            ;;
        *) return 1 ;;
    esac
}

weather_cache_read_usable() {
    local cache_file="$1"
    local expected_type="${2:-any}"
    local payload
    [[ -s "$cache_file" ]] || return 1
    # Read the cache with Bash's redirection shortcut instead of a `cat` process.
    # Command substitution keeps the same trailing-newline behavior.
    payload=$(<"$cache_file") || return 1
    weather_payload_usable "$payload" "$expected_type" || return 1
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

# Normalize epoch timestamps before arithmetic. Bash arithmetic is signed
# 64-bit on supported targets; trimming leading zeroes first both prevents
# accidental octal interpretation and lets us reject overflow lexically.
weather_normalize_epoch() {
    local raw="${1:-}"
    local LC_ALL=C
    unset WEATHER_NORMALIZED_EPOCH
    [[ "$raw" =~ ^[0-9]{1,64}$ ]] || return 1
    while [[ ${#raw} -gt 1 && "${raw:0:1}" == "0" ]]; do
        raw="${raw:1}"
    done
    (( ${#raw} <= 19 )) || return 1
    if [[ ${#raw} -eq 19 && "$raw" > "9223372036854775807" ]]; then
        return 1
    fi
    WEATHER_NORMALIZED_EPOCH="$raw"
}

weather_attempt_recent() {
    local attempt_file="$1" now="$2" modified age extra fd marker_size
    [[ -f "$attempt_file" ]] || return 1

    # Attempt markers are written as exactly one decimal timestamp followed
    # by one newline. Bound the file before reading it; Bash `read` ignores
    # NUL bytes, so EOF checks alone cannot prove the file contains only the
    # expected bytes. A valid signed 64-bit epoch has at most 19 decimal
    # digits, so the canonical marker cannot exceed 20 bytes including LF.
    # The stat check is confined to the retry/error path and avoids loading
    # an oversized or binary marker into a shell variable.
    marker_size=$(stat -c %s -- "$attempt_file" 2>/dev/null) || return 1
    [[ "$marker_size" =~ ^[0-9]{1,2}$ ]] || return 1
    (( marker_size >= 2 && marker_size <= 20 )) || return 1

    # Read through one descriptor so the second read proves there is no
    # second line, without spawning cat/wc or duplicating the marker contents.
    exec {fd}< "$attempt_file" || return 1
    if ! IFS= read -r modified <&"$fd"; then
        exec {fd}<&-
        return 1
    fi
    if IFS= read -r extra <&"$fd" || [[ -n "$extra" ]]; then
        exec {fd}<&-
        return 1
    fi
    exec {fd}<&-

    weather_normalize_epoch "$modified" || return 1
    # Require one byte for LF after the original decimal text. This catches
    # NULs that Bash `read` silently discards, as well as any hidden suffix.
    (( marker_size == ${#modified} + 1 )) || return 1
    modified="$WEATHER_NORMALIZED_EPOCH"
    weather_normalize_epoch "$now" || return 1
    now="$WEATHER_NORMALIZED_EPOCH"
    unset WEATHER_NORMALIZED_EPOCH
    age=$((now - modified))
    (( age >= 0 && age < WEATHER_ERROR_RETRY_TTL ))
}

weather_mark_attempt() {
    local attempt_file="$1" now="$2" tmp_file
    weather_normalize_epoch "$now" || return 1
    now="$WEATHER_NORMALIZED_EPOCH"
    unset WEATHER_NORMALIZED_EPOCH
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
    # A token is sent as an HTTP header through stdin. Refuse all ASCII
    # control characters, not only CR/LF, so malformed secrets cannot inject
    # header lines or rely on curl's handling of invalid field-value bytes.
    local LC_ALL=C
    if [[ "$token" == *[[:cntrl:]]* ]]; then
        echo "Ошибка: токен Gismeteo содержит недопустимый управляющий символ" >&2
        return 1
    fi
    printf '%s' "$token"
}
