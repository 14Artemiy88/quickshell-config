#!/bin/bash

_get_network_connections_unlocked() {
    local cache_file="$1"
    local cache_time_file="$2"
    # Bash 5 provides EPOCHSECONDS without launching an external `date`
    # process on each poll. Retain the external fallback for older Bash builds.
    local now="${EPOCHSECONDS:-}" cached_payload
    [[ "$now" =~ ^[0-9]+$ ]] || now=$(date +%s)

    if [[ -f "$cache_time_file" ]]; then
        local t
        read -r t < "$cache_time_file" || true
        if [[ "$t" =~ ^[0-9]+$ ]] && (( now - t < 2 )) && [[ -f "$cache_file" ]]; then
            # The cached payload is one JSON line. Read it with a shell builtin
            # rather than starting `cat` on every cache hit.
            IFS= read -r cached_payload < "$cache_file" || cached_payload=''
            [[ -z "$cached_payload" ]] || printf '%s\n' "$cached_payload"
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
        # This runs once per connection whenever the cache refreshes. A small
        # command substitution here would create a subshell for every row; use
        # a direct assignment instead while preserving the on/off semantics.
        if [[ -n "${device:-}" ]]; then
            status=on
        else
            status=off
        fi
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
    local now="${EPOCHSECONDS:-}" cached_at='' cached_payload=''

    # A fresh cache payload is published with atomic rename, and its timestamp
    # is published atomically as well. Therefore a valid hit can be read before
    # acquiring the inter-process lock: readers still see a complete JSON line,
    # while the frequent System Monitor cache-hit path avoids a subshell and a
    # `flock` process. Expired/missing cache data continues through the locked
    # path below, which rechecks freshness after taking the lock.
    if [[ "$now" =~ ^[0-9]+$ && -n "$cache_file" && -n "$cache_time_file" && \
          -f "$cache_file" && -f "$cache_time_file" ]]; then
        IFS= read -r cached_at < "$cache_time_file" || cached_at=''
        if [[ "$cached_at" =~ ^[0-9]+$ ]] && (( now - cached_at < 2 )); then
            IFS= read -r cached_payload < "$cache_file" || cached_payload=''
            if [[ -n "$cached_payload" ]]; then
                printf '%s\n' "$cached_payload"
                return 0
            fi
        fi
    fi

    # Recheck cache only after taking the lock on misses/expired data. Multiple
    # concurrent polls then share one nmcli execution, and each reader sees a
    # complete cached JSON file.
    if command -v flock >/dev/null 2>&1 && [[ -n "$cache_file" ]]; then
        (
            # Restrictive umask secures a newly-created lock file without
            # launching chmod on each cache lookup. Existing locks were
            # already hardened by earlier versions.
            umask 077
            exec 9>"${cache_file}.lock" || exit 1
            flock -x 9 || exit 1
            _get_network_connections_unlocked "$cache_file" "$cache_time_file"
        )
    else
        _get_network_connections_unlocked "$cache_file" "$cache_time_file"
    fi
}
