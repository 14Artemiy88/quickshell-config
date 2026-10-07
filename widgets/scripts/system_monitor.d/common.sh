#!/bin/bash

format_bytes() {
    local b="${1:-0}"
    b="${b%%.*}"
    if (( b >= 1099511627776 )); then env LC_NUMERIC=C printf "%.2f TB\n" "$(LC_NUMERIC=C bc <<< "scale=2; $b / 1099511627776")"
    elif (( b >= 1073741824 )); then env LC_NUMERIC=C printf "%.2f GB\n" "$(LC_NUMERIC=C bc <<< "scale=2; $b / 1073741824")"
    elif (( b >= 1048576 )); then env LC_NUMERIC=C printf "%.2f MB\n" "$(LC_NUMERIC=C bc <<< "scale=2; $b / 1048576")"
    elif (( b >= 1024 )); then env LC_NUMERIC=C printf "%.2f KB\n" "$(LC_NUMERIC=C bc <<< "scale=2; $b / 1024")"
    else printf "%s B\n" "$b"
    fi
}

escape_json_string() {
    local value="${1:-}"
    value="${value//\\/\\\\}"
    value="${value//\"/\\\"}"
    printf '%s' "$value"
}
