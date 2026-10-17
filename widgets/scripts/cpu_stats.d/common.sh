#!/bin/bash

# Linux already includes guest/guest_nice in user/nice, so do not add them
# again to total. Treat idle and iowait as non-busy time and include IRQ,
# softIRQ and steal time in the busy portion.
# Read per-core CPU counters from /proc/stat as: cpuN busy_ticks total_ticks.
# Keeping the CPU id beside each snapshot is important: CPU hotplug/online
# changes can otherwise shift array positions and compare counters from two
# different cores, producing a false utilization spike or drop.
cpu_read_counters_with_ids() {
    local stat_path="${1:-/proc/stat}"
    local cpu user nice system idle iowait irq softirq steal guest guest_nice
    local total busy valid counter

    while read -r cpu user nice system idle iowait irq softirq steal guest guest_nice; do
        [[ "${cpu:-}" =~ ^cpu[0-9]+$ ]] || continue
        # user/nice/system/idle are the four mandatory /proc/stat counters.
        # Older kernels may omit fields after idle, but a truncated mandatory
        # prefix must not be filled with zeros and accepted as a real sample.
        valid=1
        for counter in "$user" "$nice" "$system" "$idle"; do
            if [[ ! "$counter" =~ ^[0-9]+$ ]]; then
                valid=0
                break
            fi
        done
        (( valid )) || continue

        # iowait and later counters are optional on older kernels.
        iowait=${iowait:-0}; irq=${irq:-0}; softirq=${softirq:-0}; steal=${steal:-0}
        guest=${guest:-0}; guest_nice=${guest_nice:-0}
        for counter in "$iowait" "$irq" "$softirq" "$steal" "$guest" "$guest_nice"; do
            if [[ ! "$counter" =~ ^[0-9]+$ ]]; then
                valid=0
                break
            fi
        done
        (( valid )) || continue

        total=$((user + nice + system + idle + iowait + irq + softirq + steal))
        busy=$((total - idle - iowait))
        printf '%s %s %s\n' "$cpu" "$busy" "$total"
    done < "$stat_path"
}

# Compatibility helper retained for callers/tests that only need the counter
# pairs without CPU ids.
cpu_read_counters() {
    cpu_read_counters_with_ids "$@" | awk '{ print $2, $3 }'
}

# Match snapshots by logical CPU id, not by row/index. A core that appears in
# the newer snapshot has no comparable baseline yet, so its first sample is 0.
# Output: cpuN percentage, in the order the newer snapshot lists the CPUs.
cpu_usage_snapshot_percentages() {
    local before_snapshot="${1:-}" after_snapshot="${2:-}"
    local cpu busy total pct delta_total delta_busy
    declare -A before_busy=() before_total=()

    while read -r cpu busy total; do
        [[ "${cpu:-}" =~ ^cpu[0-9]+$ && "${busy:-}" =~ ^[0-9]+$ && "${total:-}" =~ ^[0-9]+$ ]] || continue
        before_busy["$cpu"]="$busy"
        before_total["$cpu"]="$total"
    done <<< "$before_snapshot"

    while read -r cpu busy total; do
        [[ "${cpu:-}" =~ ^cpu[0-9]+$ && "${busy:-}" =~ ^[0-9]+$ && "${total:-}" =~ ^[0-9]+$ ]] || continue
        pct=0
        if [[ -n "${before_busy[$cpu]+present}" && -n "${before_total[$cpu]+present}" ]]; then
            # Inline the small integer calculation instead of invoking a
            # command substitution for every logical CPU on each sample.
            # This function can run once per second on systems with many cores.
            delta_total=$((total - before_total[$cpu]))
            delta_busy=$((busy - before_busy[$cpu]))
            if (( delta_total > 0 && delta_busy >= 0 )); then
                pct=$((delta_busy * 100 / delta_total))
                (( pct < 0 )) && pct=0
                (( pct > 100 )) && pct=100
            fi
        fi
        printf '%s %s\n' "$cpu" "$pct"
    done <<< "$after_snapshot"
}

# Read the aggregate CPU counters from the first "cpu" row in /proc/stat.
# Output busy_ticks total_ticks using the same accounting as per-core metrics.
cpu_read_aggregate_counters() {
    local stat_path="${1:-/proc/stat}"
    local cpu user nice system idle iowait irq softirq steal guest guest_nice
    local total busy valid counter

    while read -r cpu user nice system idle iowait irq softirq steal guest guest_nice; do
        [[ "$cpu" == "cpu" ]] || continue
        # Keep aggregate validation identical to per-core parsing: require the
        # mandatory four counters, default only optional fields, then validate
        # any optional counters that were actually provided.
        valid=1
        for counter in "$user" "$nice" "$system" "$idle"; do
            if [[ ! "$counter" =~ ^[0-9]+$ ]]; then
                valid=0
                break
            fi
        done
        (( valid )) || continue

        iowait=${iowait:-0}; irq=${irq:-0}; softirq=${softirq:-0}; steal=${steal:-0}
        guest=${guest:-0}; guest_nice=${guest_nice:-0}
        for counter in "$iowait" "$irq" "$softirq" "$steal" "$guest" "$guest_nice"; do
            if [[ ! "$counter" =~ ^[0-9]+$ ]]; then
                valid=0
                break
            fi
        done
        (( valid )) || continue
        total=$((user + nice + system + idle + iowait + irq + softirq + steal))
        busy=$((total - idle - iowait))
        printf '%s %s\n' "$busy" "$total"
        return 0
    done < "$stat_path"
    return 1
}

# Convert two busy/total snapshots to a bounded integer percentage.
cpu_usage_percent() {
    local before_busy="${1:-0}" before_total="${2:-0}"
    local after_busy="${3:-0}" after_total="${4:-0}"
    local delta_total delta_busy pct

    delta_total=$((after_total - before_total))
    delta_busy=$((after_busy - before_busy))
    if (( delta_total <= 0 || delta_busy < 0 )); then
        printf '0'
        return 0
    fi

    pct=$((delta_busy * 100 / delta_total))
    (( pct < 0 )) && pct=0
    (( pct > 100 )) && pct=100
    printf '%s' "$pct"
}

# Calculate used physical memory using Linux's MemAvailable estimate. Keeping
# this shared with every collector avoids depending on the version/output
# semantics of `free`, which can report a different value on older procps.
mem_usage_percent() {
    local meminfo_path="${1:-/proc/meminfo}"
    local key value total=0 available=0 used pct

    # /proc/meminfo is tiny and these two fields are all the percentage needs.
    # Parse with Bash built-ins to avoid starting AWK on every memory poll.
    while read -r key value _; do
        case "$key" in
            MemTotal:) [[ "${value:-}" =~ ^[0-9]+$ ]] && total="$value" ;;
            MemAvailable:) [[ "${value:-}" =~ ^[0-9]+$ ]] && available="$value" ;;
        esac
        [[ "$total" != 0 && "$key" == MemAvailable: ]] && break
    done < "$meminfo_path"

    if (( total > 0 )); then
        (( available < 0 )) && available=0
        (( available > total )) && available="$total"
        used=$((total - available))
        # Round to the nearest whole percent, matching the prior printf format.
        pct=$(( (used * 100 + total / 2) / total ))
        (( pct < 0 )) && pct=0
        (( pct > 100 )) && pct=100
        printf '%s' "$pct"
    else
        printf '0'
    fi
}
