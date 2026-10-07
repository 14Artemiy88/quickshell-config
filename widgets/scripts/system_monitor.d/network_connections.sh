#!/bin/bash

get_network_connections() {
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

    local result
    result=$(nmcli -g NAME,TYPE,DEVICE c 2>/dev/null | awk -F: '
    BEGIN {
        icons["vpn"] = "󰒘"; icons["802-3-ethernet"] = "󰈀"; icons["wifi"] = "󰖩"
        icons["802-11-wireless"] = ""; icons["bluetooth"] = ""; icons["bridge"] = "󰡨"
        icons["tun"] = "󱠾"; icons["wireguard"] = "󰠥"
        printf "["
    }
    $2 != "tun" && $2 != "bridge" && $2 != "loopback" {
        status = ($3 == "") ? "off" : "on"
        icon = ($2 in icons) ? icons[$2] : ""
        if (sep) printf ","
        printf "{\"name\":\"%s\",\"type\":\"%s\",\"status\":\"%s\"}", $1, icon, status
        sep = 1
    }
    END { printf "]" }')

    printf '%s\n' "$result" > "$cache_file"
    printf '%s\n' "$now" > "$cache_time_file"
    printf '%s\n' "$result"
}
