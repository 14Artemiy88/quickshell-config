#!/bin/bash

_get_network_connections_unlocked() {
    local cache_file="$1"
    local cache_time_file="$2"
    local now
    now=$(date +%s)

    if [[ -f "$cache_time_file" ]]; then
        local t
        read -r t < "$cache_time_file" || true
        if [[ "$t" =~ ^[0-9]+$ ]] && (( now - t < 2 )) && [[ -f "$cache_file" ]]; then
            cat "$cache_file"
            return
        fi
    fi

    # nmcli terse output escapes colons and backslashes inside field values.
    # Decode those escapes and pass the three fields through NUL-delimited
    # records, so unusual connection names cannot be split by tabs or spaces.
    # All returned rows are encoded as one JSON array in one jq invocation.
    local name conn_type device icon status result
    local -a entries=()
    while IFS= read -r -d '' name && \
          IFS= read -r -d '' conn_type && \
          IFS= read -r -d '' device; do
        [[ -n "${name:-}" && -n "${conn_type:-}" ]] || continue
        case "$conn_type" in
            tun|bridge|loopback) continue ;;
            vpn) icon="󰒘" ;;
            802-3-ethernet) icon="󰈀" ;;
            wifi) icon="󰖩" ;;
            802-11-wireless) icon="" ;;
            bluetooth) icon="" ;;
            wireguard) icon="󰠥" ;;
            *) icon="" ;;
        esac
        status=$([[ -n "${device:-}" ]] && printf 'on' || printf 'off')
        entries+=("$name" "$icon" "$status")
    done < <(nmcli -t -e yes -g NAME,TYPE,DEVICE c 2>/dev/null | awk '
        function split_record(line, field,    i, c, nextc, n) {
            field[1] = field[2] = field[3] = ""
            n = 1
            for (i = 1; i <= length(line); i++) {
                c = substr(line, i, 1)
                if (c == "\\" && i < length(line)) {
                    nextc = substr(line, i + 1, 1)
                    if (nextc == ":" || nextc == "\\") {
                        field[n] = field[n] nextc
                        i++
                    } else {
                        field[n] = field[n] c
                    }
                } else if (c == ":" && n < 3) {
                    n++
                } else {
                    field[n] = field[n] c
                }
            }
            return n
        }
        {
            delete fields
            if (split_record($0, fields) == 3)
                printf "%s%c%s%c%s%c", fields[1], 0, fields[2], 0, fields[3], 0
        }
    ')

    if ((${#entries[@]})); then
        result=$(jq -cn --args '
            $ARGS.positional as $fields |
            [range(0; (($fields | length) / 3 | floor)) as $i |
                {name:$fields[$i * 3], type:$fields[$i * 3 + 1], status:$fields[$i * 3 + 2]}]
        ' -- "${entries[@]}") || result='[]'
    else
        result='[]'
    fi

    # Publish cache payload and timestamp via temporary files. Callers hold the
    # per-cache lock, so another poll cannot observe a half-written JSON result.
    local cache_tmp time_tmp
    cache_tmp="$(mktemp "${cache_file}.tmp.XXXXXX" 2>/dev/null)" || cache_tmp=""
    time_tmp="$(mktemp "${cache_time_file}.tmp.XXXXXX" 2>/dev/null)" || time_tmp=""
    if [[ -n "$cache_tmp" && -n "$time_tmp" ]] && \
       printf '%s\n' "$result" > "$cache_tmp" && \
       printf '%s\n' "$now" > "$time_tmp"; then
        chmod 600 "$cache_tmp" "$time_tmp" 2>/dev/null || true
        if mv -f -- "$cache_tmp" "$cache_file"; then
            mv -f -- "$time_tmp" "$cache_time_file" || rm -f -- "$time_tmp"
        else
            rm -f -- "$cache_tmp" "$time_tmp"
        fi
    else
        [[ -z "$cache_tmp" ]] || rm -f -- "$cache_tmp"
        [[ -z "$time_tmp" ]] || rm -f -- "$time_tmp"
    fi
    printf '%s\n' "$result"
}

get_network_connections() {
    local cache_file="${1:-}"
    local cache_time_file="${2:-}"

    # Recheck cache only after taking the lock. Multiple concurrent polls then
    # share one nmcli execution, and each reader sees a complete cached JSON file.
    if command -v flock >/dev/null 2>&1 && [[ -n "$cache_file" ]]; then
        (
            exec 9>"${cache_file}.lock" || exit 1
            chmod 600 "${cache_file}.lock" 2>/dev/null || true
            flock -x 9 || exit 1
            _get_network_connections_unlocked "$cache_file" "$cache_time_file"
        )
    else
        _get_network_connections_unlocked "$cache_file" "$cache_time_file"
    fi
}
