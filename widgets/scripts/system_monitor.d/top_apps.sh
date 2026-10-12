#!/bin/bash

# Build a full process snapshot as TSV: comm, CPU %, RSS KiB, PID, PPID.
# Keep PPID so Firefox-family isolated web-content processes can be attributed
# to their owning browser instead of appearing as unrelated applications.
get_process_snapshot() {
    local line pid ppid pcpu rss comm
    while IFS= read -r line; do
        read -r pid ppid pcpu rss comm <<< "$line"
        [[ -z "${pid:-}" || -z "${comm:-}" ]] && continue
        printf '%s\t%s\t%s\t%s\t%s\n' "$comm" "${pcpu:-0}" "${rss:-0}" "$pid" "$ppid"
    done < <(LC_ALL=C ps --no-header -eo pid,ppid,pcpu,rss,comm)
}

# Aggregate rows by application group. Most programs are grouped by comm as
# before. Firefox-family browsers also spawn processes named "Isolated Web Co"
# (the Linux comm name is truncated); those descendants are assigned to the
# nearest Zen/Firefox-family ancestor in the process tree.
# Input TSV: comm, CPU %, RSS KiB, PID, PPID.
# Output TSV: group name, aggregated metric, member count, representative PID.
aggregate_process_rows() {
    local metric="${1:-cpu}"
    local tab=$'\t'
    [[ "$metric" == "mem" ]] || metric="cpu"

    LC_ALL=C awk -F '\t' -v metric="$metric" '
        function is_browser_root(name) {
            return name == "zen" || name == "zen-bin" || \
                   name == "firefox" || name == "firefox-bin" || name == "firefox-esr" || \
                   name == "librewolf" || name == "librewolf-bin" || \
                   name == "floorp" || name == "waterfox"
        }
        function canonical_browser(name) {
            if (name == "zen" || name == "zen-bin") return "zen"
            if (name == "firefox" || name == "firefox-bin" || name == "firefox-esr") return "firefox"
            if (name == "librewolf" || name == "librewolf-bin") return "librewolf"
            return name
        }
        NF >= 5 {
            i = ++row_count
            proc_name[i] = $1
            proc_cpu[i] = $2 + 0
            proc_rss[i] = $3 + 0
            proc_pid[i] = $4
            proc_ppid[i] = $5
            pid_name[proc_pid[i]] = proc_name[i]
            pid_parent[proc_pid[i]] = proc_ppid[i]
        }
        END {
            for (i = 1; i <= row_count; i++) {
                name = proc_name[i]
                group = name

                # Browser helper process name is truncated by Linux comm(2).
                # Resolve its owner by walking the parent chain instead of
                # globally merging all such helpers (multiple browsers may run).
                if (name ~ /^Isolated Web Co/) {
                    parent = proc_ppid[i]
                    for (depth = 0; depth < 32 && parent != "" && parent > 1; depth++) {
                        parent_name = pid_name[parent]
                        if (is_browser_root(parent_name)) {
                            group = canonical_browser(parent_name)
                            break
                        }
                        next_parent = pid_parent[parent]
                        if (next_parent == "" || next_parent == parent) break
                        parent = next_parent
                    }
                } else if (is_browser_root(name)) {
                    group = canonical_browser(name)
                }

                cpu = proc_cpu[i]
                rss = proc_rss[i]
                pid = proc_pid[i]
                if (!(group in seen)) {
                    seen[group] = 1
                    order[++group_count] = group
                    count[group] = 0
                }
                cpu_total[group] += cpu
                rss_total[group] += rss
                count[group]++

                if (count[group] == 1 || cpu > best_cpu[group]) {
                    best_cpu[group] = cpu
                    cpu_pid[group] = pid
                }
                if (count[group] == 1 || rss > best_rss[group]) {
                    best_rss[group] = rss
                    mem_pid[group] = pid
                }
            }

            for (j = 1; j <= group_count; j++) {
                group = order[j]
                if (metric == "mem") {
                    value = rss_total[group]
                    pid = mem_pid[group]
                } else {
                    value = cpu_total[group]
                    pid = cpu_pid[group]
                }
                printf "%s\t%.4f\t%d\t%s\n", group, value, count[group], pid
            }
        }
    ' | LC_ALL=C sort -t "$tab" -k2,2nr | awk 'NR <= 5'
}

# Returns the five heaviest application groups for CPU and resident memory.
# Values and ratios use each group total, including attributed browser helpers.
get_top_apps() {
    local snapshot cpu_rows mem_rows line name total process_count pid
    local max_cpu max_rss ratio display entry
    local cpu_json='[]' mem_json='[]'
    local -a cpu_entries=() mem_entries=()

    snapshot="$(get_process_snapshot)"
    cpu_rows="$(printf '%s\n' "$snapshot" | aggregate_process_rows cpu)"
    mem_rows="$(printf '%s\n' "$snapshot" | aggregate_process_rows mem)"

    max_cpu="$(printf '%s\n' "$cpu_rows" | awk -F '\t' 'BEGIN { max=0 } NF >= 2 { if (($2 + 0) > max) max=$2 + 0 } END { printf "%.4f", max }')"
    while IFS=$'\t' read -r name total process_count pid; do
        [[ -z "${name:-}" ]] && continue
        ratio="$(awk -v value="$total" -v max="$max_cpu" 'BEGIN { if (max > 0) printf "%.4f", value / max; else print "0" }')"
        display="$(awk -v value="$total" 'BEGIN { printf "%.1f%%", value + 0 }')"
        entry="$(jq -cn --arg name "$name" --arg value "$display" --arg pid "$pid" --argjson processCount "$process_count" --argjson ratio "$ratio" '{name:$name,value:$value,pid:$pid,processCount:$processCount,ratio:$ratio}')"
        cpu_entries+=("$entry")
    done <<< "$cpu_rows"

    max_rss="$(printf '%s\n' "$mem_rows" | awk -F '\t' 'BEGIN { max=0 } NF >= 2 { if (($2 + 0) > max) max=$2 + 0 } END { printf "%.4f", max }')"
    while IFS=$'\t' read -r name total process_count pid; do
        [[ -z "${name:-}" ]] && continue
        ratio="$(awk -v value="$total" -v max="$max_rss" 'BEGIN { if (max > 0) printf "%.4f", value / max; else print "0" }')"
        display="$(awk -v value="$total" 'BEGIN { value += 0; if (value >= 1048576) printf "%.1f Gb", value / 1048576; else if (value >= 1024) printf "%.1f Mb", value / 1024; else printf "%.0f Kb", value }')"
        entry="$(jq -cn --arg name "$name" --arg value "$display" --arg pid "$pid" --argjson processCount "$process_count" --argjson ratio "$ratio" '{name:$name,value:$value,pid:$pid,processCount:$processCount,ratio:$ratio}')"
        mem_entries+=("$entry")
    done <<< "$mem_rows"

    if ((${#cpu_entries[@]})); then
        cpu_json="$(printf '%s\n' "${cpu_entries[@]}" | jq -s '.')"
    fi
    if ((${#mem_entries[@]})); then
        mem_json="$(printf '%s\n' "${mem_entries[@]}" | jq -s '.')"
    fi

    jq -cn --argjson cpu "$cpu_json" --argjson mem "$mem_json" '{cpu:$cpu,mem:$mem}'
}
