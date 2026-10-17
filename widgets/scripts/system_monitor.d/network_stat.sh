#!/bin/bash

_get_network_stat_unlocked() {
    local state_file="$1"
    local proc_net_dev="${2:-/proc/net/dev}"
    local proc_uptime="${3:-/proc/uptime}"
    local sys_class_net="${4:-/sys/class/net}"
    local prev_up=0 prev_down=0 prev_time_cs='' prev_signature='' have_previous=0 have_previous_time=0
    local result cd cu sd su state_tmp now_cs uptime uptime_seconds uptime_fraction
    local iface_path iface ifindex iflink line counters rx tx selected_filter=0
    local interface_signature current_signature signature_prefix iface_name insert_at
    local -a dev_fields=() active_interface_names=() sorted_interface_names=()
    local -A counted_interfaces=() active_interfaces=()

    # The first sample establishes a baseline only. Without a previous sample,
    # counter totals are not a meaningful speed measurement and can create a
    # huge one-frame spike in the UI after login or a runtime-dir reset.
    if [[ -f "$state_file" ]]; then
        read -r prev_up prev_down prev_time_cs prev_signature < "$state_file" || true
        if [[ "$prev_up" =~ ^[0-9]+$ && "$prev_down" =~ ^[0-9]+$ ]]; then
            have_previous=1
            if [[ "${prev_time_cs:-}" =~ ^[0-9]+$ ]]; then
                have_previous_time=1
            fi
        else
            prev_up=0
            prev_down=0
            prev_time_cs=''
            prev_signature=''
        fi
    fi

    if [[ ! -r "$proc_net_dev" ]]; then
        printf '{"down":"0 B","up":"0 B","speed_down":"0 B/s","speed_up":"0 B/s"}'
        return 0
    fi

    # `/proc/net/dev` includes virtual interfaces as well as physical/network
    # device interfaces. Summing both sides of a VPN, bridge or container link
    # can count the same payload more than once (for example tun0 + wlan0).
    # Prefer device-backed leaf interfaces: an exposed hardware/virtual NIC has
    # a `device` link and usually ifindex == iflink. If sysfs is unavailable or
    # exposes no such interface (minimal containers), retain the old non-lo
    # aggregation so network stats remain useful in restricted environments.
    if [[ -d "$sys_class_net" ]]; then
        for iface_path in "$sys_class_net"/*; do
            [[ -e "$iface_path" ]] || continue
            iface="${iface_path##*/}"
            [[ "$iface" != "lo" && -e "$iface_path/device" ]] || continue
            ifindex=""; iflink=""
            IFS= read -r ifindex < "$iface_path/ifindex" 2>/dev/null || true
            IFS= read -r iflink < "$iface_path/iflink" 2>/dev/null || true
            if [[ "$ifindex" =~ ^[0-9]+$ && "$iflink" =~ ^[0-9]+$ && "$ifindex" == "$iflink" ]]; then
                counted_interfaces["$iface"]=1
            fi
        done
        if ((${#counted_interfaces[@]} > 0)); then
            selected_filter=1
        fi
    fi

    cd=0
    cu=0
    while IFS= read -r line; do
        [[ "$line" == *:* ]] || continue
        iface="${line%%:*}"
        iface="${iface//[[:space:]]/}"
        [[ -n "$iface" && "$iface" != "lo" ]] || continue
        if (( selected_filter )) && [[ -z "${counted_interfaces[$iface]+present}" ]]; then
            continue
        fi
        counters="${line#*:}"
        read -r -a dev_fields <<< "$counters"
        ((${#dev_fields[@]} >= 9)) || continue
        rx="${dev_fields[0]}"
        tx="${dev_fields[8]}"
        [[ "$rx" =~ ^[0-9]+$ && "$tx" =~ ^[0-9]+$ ]] || continue
        if [[ -z "${active_interfaces[$iface]+present}" ]]; then
            active_interfaces["$iface"]=1
            active_interface_names+=("$iface")
        fi
        cd=$((cd + 10#$rx))
        cu=$((cu + 10#$tx))
    done < "$proc_net_dev"

    # Store the identity of the interfaces included in this sample alongside
    # the aggregate counters. When the active interface set changes (for
    # example, switching from Ethernet to Wi-Fi), cumulative counters from two
    # different sets are not comparable and could create a false speed spike.
    if (( selected_filter )); then signature_prefix='device:'; else signature_prefix='fallback:'; fi
    if ((${#active_interface_names[@]} > 0)); then
        # Sort names in-process so merely changing /proc/net/dev display order
        # does not reset the rate baseline, without spawning another utility on
        # every poll. Interface counts are small, so insertion sort is enough.
        sorted_interface_names=()
        for iface_name in "${active_interface_names[@]}"; do
            insert_at=${#sorted_interface_names[@]}
            while (( insert_at > 0 )) && [[ "${sorted_interface_names[insert_at-1]}" > "$iface_name" ]]; do
                sorted_interface_names[insert_at]="${sorted_interface_names[insert_at-1]}"
                insert_at=$((insert_at - 1))
            done
            sorted_interface_names[insert_at]="$iface_name"
        done
        interface_signature=''
        for iface_name in "${sorted_interface_names[@]}"; do
            interface_signature+="${#iface_name}:$iface_name;"
        done
    else
        interface_signature=''
    fi
    current_signature="${signature_prefix}${interface_signature}"

    # `speed_*` must be a rate, not a raw byte delta: the monitor interval is
    # user-configurable (200 ms to 10 s). Use /proc/uptime centiseconds, which
    # is monotonic and avoids wall-clock adjustments and date's 1-second floor.
    if IFS=' ' read -r uptime _ < "$proc_uptime" 2>/dev/null && [[ "$uptime" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
        uptime_seconds="${uptime%%.*}"
        if [[ "$uptime" == *.* ]]; then
            uptime_fraction="${uptime#*.}00"
            uptime_fraction="${uptime_fraction:0:2}"
        else
            uptime_fraction='00'
        fi
        [[ "$uptime_seconds" =~ ^[0-9]+$ && "$uptime_fraction" =~ ^[0-9]{2}$ ]] && \
            now_cs=$((10#$uptime_seconds * 100 + 10#$uptime_fraction))
    fi
    [[ "${now_cs:-}" =~ ^[0-9]+$ ]] || now_cs=''

    sd=0
    su=0
    if (( have_previous && have_previous_time )) && [[ "$now_cs" =~ ^[0-9]+$ && "$prev_signature" == "$current_signature" ]]; then
        # Convert delta bytes / elapsed centiseconds into bytes per second.
        # These counters have been validated as decimal integers; Bash arithmetic
        # avoids launching a second AWK process on every network poll.
        # Counter resets and non-positive elapsed time produce a safe zero.
        local elapsed_cs delta_down delta_up
        elapsed_cs=$((10#$now_cs - 10#$prev_time_cs))
        delta_down=$((10#$cd - 10#$prev_down))
        delta_up=$((10#$cu - 10#$prev_up))
        if (( elapsed_cs > 0 && delta_down >= 0 && delta_up >= 0 )); then
            sd=$((delta_down * 100 / elapsed_cs))
            su=$((delta_up * 100 / elapsed_cs))
        fi
    fi

    local -a formatted_bytes=()
    format_bytes_batch_values "$cd" "$cu" "$sd" "$su"
    formatted_bytes=("${FORMATTED_BYTES_BATCH[@]}")
    # All four inputs are integers produced from validated proc counters. If
    # the formatter unexpectedly returns fewer lines, keep the JSON safe.
    while ((${#formatted_bytes[@]} < 4)); do formatted_bytes+=("0 B"); done
    printf '{"down":"%s","up":"%s","speed_down":"%s/s","speed_up":"%s/s"}' \
        "${formatted_bytes[0]}" \
        "${formatted_bytes[1]}" \
        "${formatted_bytes[2]}" \
        "${formatted_bytes[3]}"

    # Publish the baseline atomically; the caller serializes readers/writers with flock.
    state_tmp="$(mktemp "${state_file}.tmp.XXXXXX" 2>/dev/null)" || state_tmp=""
    if [[ -n "$state_tmp" ]]; then
        if printf '%s %s %s %s\n' "$cu" "$cd" "${now_cs:--}" "$current_signature" > "$state_tmp"; then
            mv -f -- "$state_tmp" "$state_file" || rm -f -- "$state_tmp"
        else
            rm -f -- "$state_tmp"
        fi
    else
        # Retain legacy behaviour if the state directory cannot create a temp file.
        printf '%s %s %s %s\n' "$cu" "$cd" "${now_cs:--}" "$current_signature" > "$state_file"
    fi
}

get_network_stat() {
    local state_file="${1:-}"
    local proc_net_dev="${2:-/proc/net/dev}"
    local proc_uptime="${3:-/proc/uptime}"
    local sys_class_net="${4:-/sys/class/net}"

    # The counters and baseline form one sample. Serialize the full read/compute/
    # commit sequence so overlapping System Monitor polls cannot reuse one delta.
    if command -v flock >/dev/null 2>&1 && [[ -n "$state_file" ]]; then
        (
            exec 9>"${state_file}.lock" || exit 1
            chmod 600 "${state_file}.lock" 2>/dev/null || true
            flock -x 9 || exit 1
            _get_network_stat_unlocked "$state_file" "$proc_net_dev" "$proc_uptime" "$sys_class_net"
        )
    else
        _get_network_stat_unlocked "$state_file" "$proc_net_dev" "$proc_uptime" "$sys_class_net"
    fi
}
