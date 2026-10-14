#!/bin/bash

format_bytes() {
    local bytes="${1:-0}"
    # Network counters are integer byte counts. Validate them before passing
    # them to awk so a malformed/empty input produces a harmless zero.
    bytes="${bytes%%.*}"
    [[ "$bytes" =~ ^[0-9]+$ ]] || bytes=0

    # Use awk instead of bc: this keeps System Monitor working on minimal
    # installations where bc is not installed. Compute two decimals by
    # truncation to preserve the previous bc(scale=2) display semantics.
    LC_ALL=C awk -v bytes="$bytes" '
        function format_scaled(value, divisor, unit, whole, fraction) {
            whole = int(value / divisor)
            fraction = int(((value - whole * divisor) * 100) / divisor)
            if (fraction < 0) fraction = 0
            if (fraction > 99) fraction = 99
            printf "%d.%02d %s\n", whole, fraction, unit
        }
        BEGIN {
            bytes += 0
            if (bytes >= 1099511627776) format_scaled(bytes, 1099511627776, "TB")
            else if (bytes >= 1073741824) format_scaled(bytes, 1073741824, "GB")
            else if (bytes >= 1048576) format_scaled(bytes, 1048576, "MB")
            else if (bytes >= 1024) format_scaled(bytes, 1024, "KB")
            else printf "%.0f B\n", bytes
        }
    '
}


# Format multiple byte counters in one awk process. Network-stat output needs
# four values each poll (RX/TX totals and RX/TX rates); invoking format_bytes
# four times starts four interpreters unnecessarily. Keep the exact display
# semantics of format_bytes(), including integer truncation and unit names.
format_bytes_batch() {
    (($#)) || return 0
    printf '%s\n' "$@" | LC_ALL=C awk '
        function format_scaled(value, divisor, unit, whole, fraction) {
            whole = int(value / divisor)
            fraction = int(((value - whole * divisor) * 100) / divisor)
            if (fraction < 0) fraction = 0
            if (fraction > 99) fraction = 99
            printf "%d.%02d %s\n", whole, fraction, unit
        }
        function format_one(input, bytes) {
            bytes = input
            sub(/[.].*/, "", bytes)
            if (bytes !~ /^[0-9]+$/) bytes = 0
            bytes += 0
            if (bytes >= 1099511627776) format_scaled(bytes, 1099511627776, "TB")
            else if (bytes >= 1073741824) format_scaled(bytes, 1073741824, "GB")
            else if (bytes >= 1048576) format_scaled(bytes, 1048576, "MB")
            else if (bytes >= 1024) format_scaled(bytes, 1024, "KB")
            else printf "%.0f B\n", bytes
        }
        { values[NR] = $0 }
        END { for (i = 1; i <= NR; i++) format_one(values[i]) }
    '
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
