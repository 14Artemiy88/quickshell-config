#!/bin/bash

# Format one byte count using Bash arithmetic/printf, with the same binary
# units and truncation semantics used by the System Monitor display.
# The result is returned in FORMAT_BYTES_RESULT so callers can batch values
# without command substitutions or external formatter processes.
_format_bytes_value() {
    local bytes="${1:-0}" bytes_num divisor unit whole remainder fraction
    bytes="${bytes%%.*}"
    [[ "$bytes" =~ ^[0-9]+$ ]] || bytes=0
    # Normalize decimal strings before arithmetic: Bash otherwise treats a
    # leading zero as octal in some arithmetic contexts.
    while [[ ${#bytes} -gt 1 && "$bytes" == 0* ]]; do bytes="${bytes#0}"; done
    bytes_num=$((10#$bytes))

    divisor=1
    unit=''
    if (( bytes_num >= 1099511627776 )); then
        divisor=1099511627776; unit=TB
    elif (( bytes_num >= 1073741824 )); then
        divisor=1073741824; unit=GB
    elif (( bytes_num >= 1048576 )); then
        divisor=1048576; unit=MB
    elif (( bytes_num >= 1024 )); then
        divisor=1024; unit=KB
    fi

    if [[ -z "$unit" ]]; then
        printf -v FORMAT_BYTES_RESULT '%d B' "$bytes_num"
        return 0
    fi
    whole=$((bytes_num / divisor))
    remainder=$((bytes_num % divisor))
    # remainder < 2^40, so multiplying it by 100 fits signed 64-bit math.
    fraction=$((remainder * 100 / divisor))
    (( fraction < 0 )) && fraction=0
    (( fraction > 99 )) && fraction=99
    printf -v FORMAT_BYTES_RESULT '%d.%02d %s' "$whole" "$fraction" "$unit"
}

format_bytes() {
    _format_bytes_value "${1:-0}"
    printf '%s\n' "$FORMAT_BYTES_RESULT"
}

# Batch formatter for callers that need several totals/rates at once. Values
# are available in FORMATTED_BYTES_BATCH for same-shell callers; stdout remains
# available for tests or other consumers that prefer line-oriented output.
format_bytes_batch_values() {
    local value
    FORMATTED_BYTES_BATCH=()
    for value in "$@"; do
        _format_bytes_value "$value"
        FORMATTED_BYTES_BATCH+=("$FORMAT_BYTES_RESULT")
    done
}

format_bytes_batch() {
    format_bytes_batch_values "$@"
    ((${#FORMATTED_BYTES_BATCH[@]})) || return 0
    printf '%s\n' "${FORMATTED_BYTES_BATCH[@]}"
}

escape_json_string() {
    local value="${1:-}"
    value="${value//\\/\\\\}"
    value="${value//\"/\\\"}"
    printf '%s' "$value"
}

# Assemble collector files into one validated System Monitor payload. Parsing,
# shape validation, per-section fallback and final encoding happen in one jq
# process instead of cat + jq validation for each section and a fifth jq to
# combine them. One invalid collector must not blank the healthy sections.
system_monitor_assemble_payload() {
    local top_file="${1:-}" net_file="${2:-}" vol_file="${3:-}" network_file="${4:-}"
    jq -n \
        --rawfile top "$top_file" \
        --rawfile net "$net_file" \
        --rawfile vol "$vol_file" \
        --rawfile network "$network_file" '
        def decode($raw): try ($raw | fromjson) catch null;
        def safe_top($raw):
            decode($raw) as $v |
            if (($v | type) == "object" and ($v.cpu | type) == "array" and ($v.mem | type) == "array")
            then $v else {cpu: [], mem: []} end;
        def safe_net($raw):
            decode($raw) as $v |
            if (($v | type) == "object" and
                ($v.down | type) == "string" and ($v.up | type) == "string" and
                ($v.speed_down | type) == "string" and ($v.speed_up | type) == "string")
            then $v
            else {down: "0 B", up: "0 B", speed_down: "0 B/s", speed_up: "0 B/s"} end;
        def safe_volumes($raw):
            decode($raw) as $v |
            if (($v | type) == "array" and all($v[]; type == "object" and
                (.num | type) == "string" and (.value | type) == "string" and (.name | type) == "string"))
            then $v else [] end;
        def safe_network($raw):
            decode($raw) as $v |
            if (($v | type) == "array" and all($v[]; type == "object" and
                (.name | type) == "string" and (.type | type) == "string" and (.status | type) == "string"))
            then $v else [] end;
        {
            top_apps: safe_top($top),
            net_stat: safe_net($net),
            volumes: safe_volumes($vol),
            network: safe_network($network)
        }
    '
}
