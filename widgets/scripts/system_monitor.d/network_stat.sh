#!/bin/bash

get_network_stat() {
    local state_file="$1"
    local prev_up=0 prev_down=0
    local result cd cu sd su

    if [[ -f "$state_file" ]]; then
        read -r prev_up prev_down < "$state_file" || true
    fi

    result=$(awk -v pd="$prev_down" -v pu="$prev_up" '
        NR > 2 {
            gsub(/:/, "")
            if ($1 != "lo") {
                cd += $2
                cu += $10
            }
        }
        END {
            sd = cd - pd; if (sd < 0) sd = 0
            su = cu - pu; if (su < 0) su = 0
            print cd, cu, sd, su
        }
    ' /proc/net/dev)

    read -r cd cu sd su <<< "$result"

    printf '{"down":"%s","up":"%s","speed_down":"%s","speed_up":"%s"}' \
        "$(format_bytes "$cd")" \
        "$(format_bytes "$cu")" \
        "$(format_bytes "$sd")" \
        "$(format_bytes "$su")"

    printf '%s %s\n' "$cu" "$cd" > "$state_file"
}
