#!/bin/bash

# Linux already includes guest/guest_nice in user/nice, so do not add them
# again to total. Treat idle and iowait as non-busy time and include IRQ,
# softIRQ and steal time in the busy portion.
# Read per-core CPU counters from /proc/stat as: cpuN busy_ticks total_ticks.
# Keeping the CPU id beside each snapshot is important: CPU hotplug/online
# changes can otherwise shift array positions and compare counters from two
# different cores, producing a false utilization spike or drop.
# Caller-variable variant for CPU collectors that run on every poll. Assigning
# multiline snapshots directly avoids a command-substitution subshell per sample.
cpu_read_counters_with_ids_into() {
    local output_var="${1:-}" stat_path="${2:-/proc/stat}"
    local cpu user nice system idle iowait irq softirq steal guest guest_nice
    local total busy valid counter output="" status=0
    [[ "$output_var" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] || return 2
    printf -v "$output_var" '%s' ''

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
        [[ -n "$output" ]] && output+=$'\n'
        output+="$cpu $busy $total"
    done < "$stat_path" || status=$?

    printf -v "$output_var" '%s' "$output"
    return "$status"
}

# Keep the stdout API for existing callers and integrations.
cpu_read_counters_with_ids() {
    local result status=0
    cpu_read_counters_with_ids_into result "${1:-/proc/stat}" || status=$?
    [[ -n "$result" ]] && printf '%s\n' "$result"
    return "$status"
}

# Compatibility helper retained for callers/tests that only need the counter
# pairs without CPU ids.
cpu_read_counters() {
    cpu_read_counters_with_ids "$@" | awk '{ print $2, $3 }'
}

# Match snapshots by logical CPU id, not by row/index. A core that appears in
# the newer snapshot has no comparable baseline yet, so its first sample is 0.
# Output: cpuN percentage, in the order the newer snapshot lists the CPUs.
cpu_usage_snapshot_percentages_into() {
    local output_var="${1:-}" before_snapshot="${2:-}" after_snapshot="${3:-}"
    local cpu busy total pct delta_total delta_busy output=""
    declare -A before_busy=() before_total=()
    [[ "$output_var" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] || return 2
    printf -v "$output_var" '%s' ''

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
        [[ -n "$output" ]] && output+=$'\n'
        output+="$cpu $pct"
    done <<< "$after_snapshot"

    printf -v "$output_var" '%s' "$output"
}

# Compatibility wrapper for callers that consume the line-oriented output.
cpu_usage_snapshot_percentages() {
    local result
    cpu_usage_snapshot_percentages_into result "${1:-}" "${2:-}"
    [[ -n "$result" ]] && printf '%s\n' "$result"
}

# Read aggregate CPU counters directly into the caller's variable. This is the
# hot-path form used by Top Apps, which polls the snapshot every refresh.
cpu_read_aggregate_counters_into() {
    local output_var="${1:-}" stat_path="${2:-/proc/stat}"
    local cpu user nice system idle iowait irq softirq steal guest guest_nice
    local total busy valid counter aggregate_value=''

    [[ "$output_var" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] || return 2
    printf -v "$output_var" '%s' ''

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
        aggregate_value="$busy $total"
        printf -v "$output_var" '%s' "$aggregate_value"
        return 0
    done < "$stat_path"
    return 1
}

# Keep the stdout API for existing callers and integrations.
cpu_read_aggregate_counters() {
    local result status=0
    cpu_read_aggregate_counters_into result "${1:-/proc/stat}" || status=$?
    [[ -n "$result" ]] && printf '%s\n' "$result"
    return "$status"
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
mem_usage_percent_into() {
    local output_var="${1:-}" meminfo_path="${2:-/proc/meminfo}"
    local key value total=0 available=0 used pct computed
    [[ "$output_var" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] || return 2
    printf -v "$output_var" '%s' '0'

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
        computed=$pct
    else
        computed=0
    fi
    printf -v "$output_var" '%s' "$computed"
}

# Keep the stdout API for external scripts and existing integrations.
mem_usage_percent() {
    local result
    mem_usage_percent_into result "${1:-/proc/meminfo}"
    printf '%s' "$result"
}
