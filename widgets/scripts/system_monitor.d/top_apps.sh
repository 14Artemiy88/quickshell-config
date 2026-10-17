#!/bin/bash

# Resolve the sibling library path with Bash parameter expansion only.
TOP_APPS_SCRIPT_PATH="${BASH_SOURCE[0]}"
TOP_APPS_SCRIPT_DIR="${TOP_APPS_SCRIPT_PATH%/*}"
[[ "$TOP_APPS_SCRIPT_DIR" != "$TOP_APPS_SCRIPT_PATH" ]] || TOP_APPS_SCRIPT_DIR=.
source "$TOP_APPS_SCRIPT_DIR/../cpu_stats.d/common.sh"

# Process command lines are only needed for plausible IDE roots. Reading just
# these few /proc/<pid>/cmdline files keeps CPU polling cheaper than adding the
# full args column for every process to `ps` output. The NUL-separated argv is
# converted to a space-separated string suitable for the TSV metadata column.
is_ide_process_candidate() {
    case "${1,,}" in
        java|javaw|goland|goland.sh|phpstorm|phpstorm.sh|pycharm|pycharm.sh|\
        webstorm|webstorm.sh|clion|clion.sh|datagrip|datagrip.sh|rider|rider.sh|\
        rustrover|rustrover.sh|rubymine|rubymine.sh|idea|idea.sh|\
        code|code-insiders|codium|eclipse|netbeans|sublime_text|zed) return 0 ;;
        *) return 1 ;;
    esac
}

read_process_cmdline() {
    local file="${1:-}" arg result=''
    [[ -r "$file" ]] || return 0
    while IFS= read -r -d '' arg; do
        [[ -n "$result" ]] && result+=' '
        result+="$arg"
    done < "$file"
    result="${result//$'\t'/ }"
    result="${result//$'\r'/ }"
    result="${result//$'\n'/ }"
    printf '%s' "$result"
}

# Build a full process snapshot as TSV: comm, CPU %, RSS KiB, PID, PPID,
# optionally followed by a root process command line for IDE attribution.
# Keep PPID so helper descendants can be assigned to their owning application.
calculate_process_cpu_snapshot() {
    local previous_file="$1" current_file="$2" now_cs="$3" clk_tck="$4"
    awk -F '\t' -v now_cs="$now_cs" -v clk_tck="$clk_tck" '
        FILENAME == ARGV[1] {
            if ($1 == "T") previous_cs = $2 + 0
            else if ($1 == "P") {
                previous_start[$2] = $3
                previous_ticks[$2] = $4 + 0
            }
            next
        }
        NF >= 6 {
            name = $1
            ticks = $2 + 0
            rss = $3 + 0
            pid = $4
            ppid = $5
            start = $6
            cpu = 0
            elapsed_cs = now_cs - previous_cs
            if (previous_cs >= 0 && elapsed_cs > 0) {
                if ((pid in previous_start) && previous_start[pid] == start) {
                    delta = ticks - previous_ticks[pid]
                    if (delta >= 0) cpu = delta * 10000 / (clk_tck * elapsed_cs)
                } else if (start ~ /^[0-9]+$/ && clk_tck > 0 && (start * 100 / clk_tck) >= previous_cs) {
                    # This PID started during the interval, so its current
                    # utime+stime ticks all belong to this sample. Previously
                    # new compiler workers were forced to 0% until the next
                    # poll, pushing their first-interval work into the
                    # synthetic system remainder row.
                    cpu = ticks * 10000 / (clk_tck * elapsed_cs)
                }
            }
            cgroup = ($7 == "" ? "-" : $7)
            cmdline = ($8 == "" ? "-" : $8)
            # Keep a stable seven-column CPU snapshot so cgroup attribution
            # works even when a process has no command-line metadata.
            printf "%s\t%.4f\t%.0f\t%s\t%s\t%s\t%s\n", name, cpu, rss, pid, ppid, cgroup, cmdline
        }
    ' "$previous_file" "$current_file"
}
# Convert aggregate CPU counters to a percentage without spawning AWK on
# every poll. Keep four decimal places as an integer scaled by 10,000, and
# round to the nearest value to match printf("%.4f") in the previous code.
calculate_system_load_percent() {
    local previous_busy="${1:-}" previous_total="${2:-}"
    local current_busy="${3:-}" current_total="${4:-}"
    local delta_busy delta_total scaled

    [[ "$previous_busy" =~ ^[0-9]+$ && "$previous_total" =~ ^[0-9]+$ && \
       "$current_busy" =~ ^[0-9]+$ && "$current_total" =~ ^[0-9]+$ ]] || {
        printf '0.0000'
        return 0
    }

    delta_total=$((10#$current_total - 10#$previous_total))
    delta_busy=$((10#$current_busy - 10#$previous_busy))
    if (( delta_total <= 0 || delta_busy < 0 )); then
        scaled=0
    else
        # percentage * 10,000 = delta_busy * 1,000,000 / delta_total.
        # Linux CPU counters advance slowly enough that this product is safe
        # in signed 64-bit Bash arithmetic for realistic sampling intervals.
        scaled=$(( (delta_busy * 1000000 + delta_total / 2) / delta_total ))
        (( scaled > 1000000 )) && scaled=1000000
    fi
    printf '%d.%04d' "$((scaled / 10000))" "$((scaled % 10000))"
}

# Calculate process CPU usage over the interval between two System Monitor polls.
# `ps %CPU` is a lifetime average, which badly overstates short-lived commands
# (for example the `ps` process used to collect this snapshot). Read CPU ticks
# from /proc/<pid>/stat and compare with the previous snapshot instead. CPU rows
# may include a sixth metadata field with an IDE JVM command line for attribution.
_get_process_snapshot_unlocked() {
    local want_cpu="${1:-1}"
    local runtime_dir="${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}"
    local uid="${UID:-$(id -u)}"
    local state_file="$runtime_dir/quickshell-top-apps-cpu-${uid}.tsv"
    local previous_file current_file next_state previous_file_is_temp=0
    local uptime uptime_seconds uptime_fraction now_cs clk_tck ps_output
    local proc_root="${TOP_APPS_PROC_ROOT:-/proc}"
    local proc_stat_path="${TOP_APPS_PROC_STAT:-/proc/stat}"
    local system_counters previous_system_counters previous_clk_tck current_busy current_total previous_busy previous_total system_load_pct
    local line pid ppid rss comm cgroup ps_remainder cmdline stat_line stat_rest
    local current_fd next_state_fd
    local state stat_ppid pgrp session tty_nr tpgid flags minflt cminflt majflt cmajflt
    local utime stime cutime cstime priority nice threads itrealvalue starttime vsize stat_rss
    local ticks
    [[ "$want_cpu" == "1" ]] || want_cpu=0

    # State lives in XDG_RUNTIME_DIR and is private to the current user.
    # Tests may point XDG_RUNTIME_DIR to an isolated temporary directory.
    [[ -d "$runtime_dir" && -w "$runtime_dir" ]] || runtime_dir="/tmp"
    state_file="$runtime_dir/quickshell-top-apps-cpu-${uid}.tsv"

    # The poll lock serializes readers/writers of state_file, so the previous
    # sample can be read in place. Avoid an extra mktemp + cat subprocess on
    # every CPU poll; create a temporary sentinel only for the first sample or
    # when CPU collection is re-enabled after RAM-only mode.
    if [[ "$want_cpu" == "1" && -r "$state_file" ]]; then
        previous_file="$state_file"
    else
        previous_file="$(mktemp "$runtime_dir/top-apps-previous.XXXXXX")" || return 1
        previous_file_is_temp=1
        printf 'T\t-1\n' > "$previous_file"
    fi
    current_file="$(mktemp "$runtime_dir/top-apps-current.XXXXXX")" || {
        [[ "$previous_file_is_temp" == "1" ]] && rm -f "$previous_file"
        return 1
    }
    next_state="$(mktemp "$runtime_dir/top-apps-state.XXXXXX")" || {
        [[ "$previous_file_is_temp" == "1" ]] && rm -f "$previous_file"
        rm -f "$current_file"
        return 1
    }

    if [[ "$want_cpu" == "1" ]]; then
        if ! IFS=' ' read -r uptime _ < /proc/uptime; then
            [[ "$previous_file_is_temp" == "1" ]] && rm -f "$previous_file"
            rm -f "$current_file" "$next_state"
            return 1
        fi
        uptime_seconds="${uptime%%.*}"
        uptime_fraction="${uptime#*.}00"
        uptime_fraction="${uptime_fraction:0:2}"
        [[ "$uptime_seconds" =~ ^[0-9]+$ && "$uptime_fraction" =~ ^[0-9]{2}$ ]] || {
            [[ "$previous_file_is_temp" == "1" ]] && rm -f "$previous_file"
            rm -f "$current_file" "$next_state"
            return 1
        }
        now_cs=$((10#$uptime_seconds * 100 + 10#$uptime_fraction))
        # CLK_TCK is invariant for this running Linux system. Reuse it from
        # the previous sample instead of spawning getconf on every poll; old
        # state files without a C record still fall back to getconf once.
        previous_system_counters=''
        previous_clk_tck=''
        while IFS=$'\t' read -r state_marker state_a state_b _; do
            case "$state_marker" in
                S) previous_system_counters="$state_a $state_b" ;;
                C) previous_clk_tck="$state_a" ;;
            esac
        done < "$previous_file"
        if [[ "$previous_clk_tck" =~ ^[1-9][0-9]*$ ]]; then
            clk_tck="$previous_clk_tck"
        else
            clk_tck="$(getconf CLK_TCK 2>/dev/null || printf '100')"
            [[ "$clk_tck" =~ ^[1-9][0-9]*$ ]] || clk_tck=100
        fi
        printf 'T\t%s\nC\t%s\n' "$now_cs" "$clk_tck" >> "$next_state"

        # Sample aggregate /proc/stat counters at the same start-of-poll point
        # as the process CPU baseline, so the residual row reflects the overall
        # busy percentage over this monitor interval.
        system_counters="$(cpu_read_aggregate_counters "$proc_stat_path" 2>/dev/null || true)"
        if [[ "$system_counters" =~ ^([0-9]+)[[:space:]]+([0-9]+)$ ]]; then
            current_busy="${BASH_REMATCH[1]}"
            current_total="${BASH_REMATCH[2]}"
            printf 'S\t%s\t%s\n' "$current_busy" "$current_total" >> "$next_state"
            # Previous S and C records were read together above using Bash,
            # avoiding both an AWK parse and a second pass over the state file.
            if [[ "$previous_system_counters" =~ ^([0-9]+)[[:space:]]+([0-9]+)$ ]]; then
                previous_busy="${BASH_REMATCH[1]}"
                previous_total="${BASH_REMATCH[2]}"
                system_load_pct="$(calculate_system_load_percent "$previous_busy" "$previous_total" "$current_busy" "$current_total")"
                printf 'L\t%s\n' "$system_load_pct" >> "$next_state"
            fi
        fi
    else
        # RAM-only polling needs process names, parent IDs and RSS from `ps`,
        # but no per-PID stat reads or CPU counter/timing work. Clear the saved
        # CPU baseline so re-enabling CPU starts with a fresh sample pair.
        printf 'T\t-1\n' >> "$next_state"
    fi

    # procps-ng exposes the owning cgroup in one snapshot. This lets us
    # attribute live descendants that detached/reparented after launch but
    # still belong to the IDE's systemd application scope.
    ps_output="$(LC_ALL=C ps -ww --no-header -eo pid,ppid,rss,cgroup,comm 2>/dev/null)" || {
        [[ "$previous_file_is_temp" == "1" ]] && rm -f "$previous_file"
        rm -f "$current_file" "$next_state"
        return 1
    }
    # Keep the output files open during the per-process loop. Appending with
    # `>>` for every PID makes Bash reopen both files repeatedly on systems
    # with many processes; persistent descriptors reduce that per-row overhead.
    exec {current_fd}>>"$current_file"
    exec {next_state_fd}>>"$next_state"
    while IFS= read -r line; do
        [[ -n "$line" ]] || continue
        # `comm` remains the final column so names containing spaces survive.
        # Fall back to the old four-column ps fixture/output for compatibility
        # with older procps wrappers and existing external test harnesses.
        read -r pid ppid rss ps_remainder <<< "$line"
        read -r cgroup comm <<< "${ps_remainder:-}"
        if [[ -z "${comm:-}" ]]; then
            comm="${cgroup:-}"
            cgroup='-'
        fi
        [[ "${pid:-}" =~ ^[0-9]+$ && -n "${comm:-}" ]] || continue
        [[ -n "${cgroup:-}" ]] || cgroup='-'

        cmdline=''
        if [[ "$want_cpu" == "1" ]] && is_ide_process_candidate "$comm"; then
            cmdline="$(read_process_cmdline "$proc_root/$pid/cmdline")"
        fi

        if [[ "$want_cpu" != "1" ]]; then
            # The RAM-only view needs just the process inventory and RSS. Do
            # not open /proc/<pid>/stat when CPU counters were not requested.
            printf '%s\t0.0000\t%s\t%s\t%s\n' "$comm" "${rss:-0}" "$pid" "$ppid" >&"$current_fd"
            continue
        fi

        [[ -r "$proc_root/$pid/stat" ]] || continue
        IFS= read -r stat_line < "$proc_root/$pid/stat" || continue

        # The comm field can contain spaces and parentheses. Strip through its
        # final closing parenthesis; the remaining fields begin at stat field 3.
        stat_rest="${stat_line##*) }"
        read -r state stat_ppid pgrp session tty_nr tpgid flags minflt cminflt majflt cmajflt \
            utime stime cutime cstime priority nice threads itrealvalue starttime vsize stat_rss \
            <<< "$stat_rest"
        [[ "${utime:-}" =~ ^[0-9]+$ && "${stime:-}" =~ ^[0-9]+$ && "${starttime:-}" =~ ^[0-9]+$ ]] || continue
        ticks=$((utime + stime))

        # Rows for CPU calculation are: comm, current ticks, RSS KiB, PID, PPID, starttime, cgroup, optional IDE command line.
        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$comm" "$ticks" "${rss:-0}" "$pid" "$ppid" "$starttime" "$cgroup" "${cmdline:--}" >&"$current_fd"
        printf 'P\t%s\t%s\t%s\n' "$pid" "$starttime" "$ticks" >&"$next_state_fd"
    done <<< "$ps_output"
    exec {current_fd}>&-
    exec {next_state_fd}>&-

    if [[ "$want_cpu" == "1" ]]; then
        # 100% means one logical core fully used. PID starttime guards against PID reuse.
        calculate_process_cpu_snapshot "$previous_file" "$current_file" "$now_cs" "$clk_tck"
    else
        cat -- "$current_file"
    fi

    # Replace the prior sample only after collecting a complete new snapshot.
    if [[ -s "$current_file" ]]; then
        mv -f -- "$next_state" "$state_file"
    fi
    [[ "$previous_file_is_temp" == "1" ]] && rm -f "$previous_file"
    rm -f "$current_file" "$next_state"
}

get_process_snapshot() {
    local want_cpu="${1:-1}"
    [[ "$want_cpu" == "1" ]] || want_cpu=0
    local runtime_dir="${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}"
    local uid="${UID:-$(id -u)}"
    local state_file
    [[ -d "$runtime_dir" && -w "$runtime_dir" ]] || runtime_dir="/tmp"
    state_file="$runtime_dir/quickshell-top-apps-cpu-${uid}.tsv"

    # Keep interval sampling single-writer: two overlapping polls must not both
    # compare against the same previous sample and then double-count the interval.
    if command -v flock >/dev/null 2>&1; then
        (
            exec 9>"${state_file}.lock" || exit 1
            chmod 600 "${state_file}.lock" 2>/dev/null || true
            flock -x 9 || exit 1
            _get_process_snapshot_unlocked "$want_cpu"
        )
    else
        _get_process_snapshot_unlocked "$want_cpu"
    fi
}

# Aggregate rows by application group. Most programs are grouped by comm as
# before. Firefox-family browsers also spawn processes named "Isolated Web Co"
# (the Linux comm name is truncated); those descendants are assigned to the
# nearest Zen/Firefox-family ancestor in the process tree.
# Input TSV: comm, CPU %, RSS KiB, PID, PPID.
# Output TSV: group name, aggregated metric, member count, representative PID.
aggregate_process_rows() {
    local metric="${1:-cpu}"
    local row_limit="${2:-5}"
    local tab=$'\t'
    [[ "$metric" == "mem" ]] || metric="cpu"
    [[ "$row_limit" =~ ^[0-9]+$ ]] || row_limit=5

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
        function ide_root_group(name, cmd, lower, lower_cmd) {
            lower = tolower(name)
            lower_cmd = tolower(cmd)

            # Native process names used by several common IDEs/editors.
            if (lower == "goland" || lower == "goland.sh") return "goland"
            if (lower == "phpstorm" || lower == "phpstorm.sh") return "phpstorm"
            if (lower == "pycharm" || lower == "pycharm.sh") return "pycharm"
            if (lower == "webstorm" || lower == "webstorm.sh") return "webstorm"
            if (lower == "clion" || lower == "clion.sh") return "clion"
            if (lower == "datagrip" || lower == "datagrip.sh") return "datagrip"
            if (lower == "rider" || lower == "rider.sh") return "rider"
            if (lower == "rustrover" || lower == "rustrover.sh") return "rustrover"
            if (lower == "rubymine" || lower == "rubymine.sh") return "rubymine"
            if (lower == "idea" || lower == "idea.sh") return "idea"
            if (lower == "code" || lower == "code-insiders" || lower == "codium") return "vscode"
            if (lower == "eclipse") return "eclipse"
            if (lower == "netbeans") return "netbeans"
            if (lower == "sublime_text") return "sublime_text"
            if (lower == "zed") return "zed"

            # JetBrains Linux launchers usually run as `java`; identify the
            # actual product from its JVM selector/prefix, not from the word
            # `java` alone. This covers GoLand, PhpStorm and the other IDEs.
            if (lower_cmd ~ /-didea[.]paths[.]selector=goland/ || lower_cmd ~ /-didea[.]platform[.]prefix=goland/) return "goland"
            if (lower_cmd ~ /-didea[.]paths[.]selector=phpstorm/ || lower_cmd ~ /-didea[.]platform[.]prefix=phpstorm/) return "phpstorm"
            if (lower_cmd ~ /-didea[.]paths[.]selector=pycharm/ || lower_cmd ~ /-didea[.]platform[.]prefix=pycharm/) return "pycharm"
            if (lower_cmd ~ /-didea[.]paths[.]selector=webstorm/ || lower_cmd ~ /-didea[.]platform[.]prefix=webstorm/) return "webstorm"
            if (lower_cmd ~ /-didea[.]paths[.]selector=clion/ || lower_cmd ~ /-didea[.]platform[.]prefix=clion/) return "clion"
            if (lower_cmd ~ /-didea[.]paths[.]selector=datagrip/ || lower_cmd ~ /-didea[.]platform[.]prefix=datagrip/) return "datagrip"
            if (lower_cmd ~ /-didea[.]paths[.]selector=rider/ || lower_cmd ~ /-didea[.]platform[.]prefix=rider/) return "rider"
            if (lower_cmd ~ /-didea[.]paths[.]selector=rustrover/ || lower_cmd ~ /-didea[.]platform[.]prefix=rustrover/) return "rustrover"
            if (lower_cmd ~ /-didea[.]paths[.]selector=rubymine/ || lower_cmd ~ /-didea[.]platform[.]prefix=rubymine/) return "rubymine"
            if (lower_cmd ~ /-didea[.]paths[.]selector=(intellijidea|ideaic|ideaiu)/ || lower_cmd ~ /-didea[.]platform[.]prefix=(idea|intellijidea)/) return "idea"

            if ((lower_cmd ~ /com[.]intellij[.]idea[.]main/ || lower_cmd ~ /com[.]intellij[.]platform[.]ide[.]bootstrap/) && lower_cmd ~ /-didea[.]paths[.]selector=/) return "jetbrains-ide"
            return ""
        }
        function ide_ancestor_group(parent, depth, next_parent) {
            for (depth = 0; depth < 48 && parent != "" && parent > 1; depth++) {
                if (pid_ide_group[parent] != "") return pid_ide_group[parent]
                next_parent = pid_parent[parent]
                if (next_parent == "" || next_parent == parent) break
                parent = next_parent
            }
            return ""
        }
        NF >= 5 {
            i = ++row_count
            proc_name[i] = $1
            proc_cpu[i] = $2 + 0
            proc_rss[i] = $3 + 0
            proc_pid[i] = $4
            proc_ppid[i] = $5
            # New CPU snapshots carry both cgroup and commandline fields. Keep
            # legacy six-column fixtures compatible (their sixth field was cmdline).
            if (NF >= 7) {
                proc_cgroup[i] = $6
                proc_cmdline[i] = ($7 == "-" ? "" : $7)
            } else {
                proc_cgroup[i] = "-"
                proc_cmdline[i] = (NF >= 6 ? $6 : "")
            }
            pid_name[proc_pid[i]] = proc_name[i]
            pid_parent[proc_pid[i]] = proc_ppid[i]
            root_group = ide_root_group(proc_name[i], proc_cmdline[i])
            pid_ide_group[proc_pid[i]] = root_group
            cgroup = proc_cgroup[i]
            if (root_group != "" && cgroup != "" && cgroup != "-") {
                if (cgroup_ambiguous[cgroup]) {
                    # A single cgroup with roots from different products is
                    # not safe to use as an attribution boundary.
                    cgroup_ide_group[cgroup] = ""
                } else if (!(cgroup in cgroup_ide_group)) {
                    cgroup_ide_group[cgroup] = root_group
                } else if (cgroup_ide_group[cgroup] != root_group) {
                    cgroup_ide_group[cgroup] = ""
                    cgroup_ambiguous[cgroup] = 1
                }
            }
        }
        END {
            for (i = 1; i <= row_count; i++) {
                name = proc_name[i]
                group = name

                # Browser helper process name is truncated by Linux comm(2).
                # Resolve its owner first so a browser launched from an IDE is
                # still shown as a browser rather than folded into the IDE.
                ide_group = ""
                if (metric == "cpu") {
                    ide_group = pid_ide_group[proc_pid[i]]
                    if (ide_group == "") ide_group = ide_ancestor_group(proc_ppid[i])
                    # If a helper daemon reparented to PID 1, the PPID chain may
                    # no longer reveal its owner. A unique JetBrains/editor
                    # systemd cgroup is the next-best boundary; never attribute
                    # from a cgroup containing multiple IDE roots.
                    cgroup = proc_cgroup[i]
                    if (ide_group == "" && cgroup != "" && cgroup != "-" && !cgroup_ambiguous[cgroup])
                        ide_group = cgroup_ide_group[cgroup]
                }
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
                    if (group == name && ide_group != "") group = ide_group
                } else if (is_browser_root(name)) {
                    group = canonical_browser(name)
                } else if (ide_group != "") {
                    # Fold live helper/build descendants into the IDE that
                    # owns their process tree. This generalizes beyond GoLand
                    # to PhpStorm and other JetBrains IDEs (plus common editors).
                    group = ide_group
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
                    # Zero-use rows are not useful in a CPU ranking and can
                    # otherwise let transient sampling helpers fill the list.
                    if (value <= 0) continue
                }
                printf "%s\t%.4f\t%d\t%s\n", group, value, count[group], pid
            }
        }
    ' | LC_ALL=C sort -t "$tab" -k2,2nr | {
        # The result is already sorted. Limit rows in this shell reader rather
        # than starting a second AWK process on every Top Apps refresh.
        emitted=0
        while IFS= read -r sorted_row; do
            if (( row_limit == 0 || emitted < row_limit )); then
                printf '%s\n' "$sorted_row"
                ((emitted += 1))
            fi
        done
    }
}

# Return the machine's available CPU capacity expressed as percent of one core
# per logical CPU. Per-process CPU values are also expressed per core and can
# exceed 100% when a process uses multiple cores.
get_cpu_capacity_percent() {
    local online_path="${TOP_APPS_CPU_ONLINE:-/sys/devices/system/cpu/online}"
    local cpuinfo_path="${TOP_APPS_CPUINFO:-/proc/cpuinfo}" line token first last count=0 online_cpus=''
    local -a ranges=()

    # Linux exposes the online CPU set directly (for example 0-3,8,10-11).
    # Parse it in Bash rather than launching getconf on every widget refresh.
    if [[ -r "$online_path" ]] && IFS= read -r online_cpus < "$online_path"; then
        if [[ "$online_cpus" =~ ^[0-9]+(-[0-9]+)?(,[0-9]+(-[0-9]+)?)*$ ]]; then
            IFS=',' read -r -a ranges <<< "$online_cpus"
            for token in "${ranges[@]}"; do
                if [[ "$token" == *-* ]]; then
                    first="${token%%-*}"
                    last="${token#*-}"
                    (( 10#$last >= 10#$first )) || { count=0; break; }
                    ((count += 10#$last - 10#$first + 1))
                else
                    ((count += 1))
                fi
            done
        fi
    fi

    if (( count <= 0 )); then
        online_cpus="$(getconf _NPROCESSORS_ONLN 2>/dev/null || true)"
        if [[ "$online_cpus" =~ ^[1-9][0-9]*$ ]]; then
            count="$online_cpus"
        else
            # Keep the final fallback in Bash too; no AWK is needed just to
            # count processor records when sysfs and getconf are unavailable.
            count=0
            while IFS= read -r line; do
                [[ "$line" =~ ^processor[[:space:]]*: ]] && ((count += 1))
            done < "$cpuinfo_path" 2>/dev/null || true
        fi
    fi
    (( count > 0 )) || count=1
    printf '%d.0000' "$((count * 100))"
}

# Return total physical memory in KiB, matching the RSS units produced above.
# /proc/meminfo is small; parse it with Bash built-ins rather than starting AWK
# for every widget refresh. An override keeps the parser easy to fixture-test.
get_total_memory_kib() {
    local meminfo_path="${TOP_APPS_MEMINFO:-/proc/meminfo}" key value unit
    while read -r key value unit _; do
        if [[ "$key" == "MemTotal:" && "$value" =~ ^[0-9]+$ && "$unit" == "kB" ]]; then
            printf '%s' "$value"
            return 0
        fi
    done < "$meminfo_path" 2>/dev/null || true
    printf '0'
}

# Express a value as a fraction of total system capacity. A process group can
# exceed physical capacity transiently (for example due to shared RSS accounting
# or CPU hotplug/sample jitter), so keep the visual bar in the expected 0..1 range.
calculate_resource_ratio() {
    local value="${1:-0}" capacity="${2:-0}"
    awk -v value="$value" -v capacity="$capacity" '
        BEGIN {
            value += 0
            capacity += 0
            ratio = (capacity > 0 && value > 0) ? value / capacity : 0
            if (ratio < 0) ratio = 0
            if (ratio > 1) ratio = 1
            printf "%.4f", ratio
        }
    '
}

# Format every row in one AWK process and encode the section in one jq process.
# The previous implementation spawned AWK for each row's ratio and label, then
# jq once per row. Since each section contains up to five apps, batching avoids
# dozens of short-lived processes without changing the JSON schema or labels.
format_top_apps_rows_json() {
    local rows="${1:-}" metric="${2:-cpu}" capacity="${3:-0}"
    printf '%s\n' "$rows" | LC_ALL=C awk -F '\t' -v metric="$metric" -v capacity="$capacity" '
        BEGIN {
            capacity += 0
        }
        NF >= 4 {
            name = $1
            value = $2 + 0
            process_count = $3 + 0
            pid = $4
            ratio = (capacity > 0 && value > 0) ? value / capacity : 0
            if (ratio < 0) ratio = 0
            if (ratio > 1) ratio = 1

            if (metric == "mem") {
                if (value >= 1048576) label = sprintf("%.1f Gb", value / 1048576)
                else if (value >= 1024) label = sprintf("%.1f Mb", value / 1024)
                else label = sprintf("%.0f Kb", value)
            } else {
                # CPU value labels and bars both use the share of total online
                # CPU capacity (for example, 75% of one core on an 8-core
                # system is shown as 9.4% of total capacity).
                label = sprintf("%.1f%%", ratio * 100)
            }
            printf "%s\t%s\t%s\t%d\t%.4f\n", name, label, pid, process_count, ratio
        }
    ' | jq -Rn '[inputs | select(length > 0) | split("\t") | {name:.[0], value:.[1], pid:.[2], processCount:(.[3]|tonumber), ratio:(.[4]|tonumber)}]'
}

# Read the last global CPU utilization sample stored alongside process counters.
# This is 0..100% of total system capacity, matching the CPU widget's semantics.
get_system_cpu_load_percent() {
    local runtime_dir="${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}"
    local uid="${UID:-$(id -u)}"
    local state_file
    [[ -d "$runtime_dir" && -w "$runtime_dir" ]] || runtime_dir="/tmp"
    state_file="$runtime_dir/quickshell-top-apps-cpu-${uid}.tsv"
    [[ -r "$state_file" ]] || { printf '0.0000\n'; return 0; }
    awk -F '\t' '$1 == "L" && $2 ~ /^[0-9]+([.][0-9]+)?$/ { value=$2; found=1; exit } END { if (found) { if (value < 0) value=0; if (value > 100) value=100; printf "%.4f\n", value } else print "0.0000" }' "$state_file"
}

# Keep the four heaviest named apps and summarize all remaining system CPU
# capacity in a fifth row. The global /proc/stat counter includes work that can
# be absent from an interval process snapshot (short-lived workers, kernel time,
# and other processes outside the visible leaders).
add_system_cpu_remainder_row() {
    local top_rows="${1:-}" load_percent="${2:-0}" capacity="${3:-0}" label="${4:-Система/прочее}"
    # Keep user-provided labels safe for the tab-separated transport format.
    label="${label//$'\t'/ }"
    label="${label//$'\r'/ }"
    label="${label//$'\n'/ }"
    label="${label:0:64}"
    label="${label#"${label%%[![:space:]]*}"}"
    label="${label%"${label##*[![:space:]]}"}"
    [[ -n "$label" ]] || label='Система/прочее'

    # One AWK process can pass through the visible rows, total their CPU usage,
    # and append the remainder. Previously this helper launched four AWK
    # processes for every CPU Top Apps poll.
    LC_ALL=C awk -F '\t' -v pct="$load_percent" -v capacity="$capacity" -v label="$label" '
        BEGIN {
            pct += 0
            capacity += 0
            if (pct < 0) pct = 0
            if (pct > 100) pct = 100
        }
        NF >= 4 {
            print $0
            used += $2 + 0
        }
        END {
            rest = pct * capacity / 100 - used
            if (rest < 0.05) rest = 0
            if (rest > 0) printf "%s\t%.4f\t1\t0\n", label, rest
        }
    ' <<< "$top_rows"
}

# CPU can either show the four heaviest named groups plus an aggregate system
# remainder, or the traditional five application groups. RAM always shows its
# five largest application groups. Bars and CPU labels use total system capacity.
get_top_apps() {
    # The additional options default to enabled/the historical label so old
    # callers retain the v670 output until they explicitly opt out.
    local want_cpu="${1:-1}" want_mem="${2:-1}"
    local show_remainder="${3:-1}" remainder_label="${4:-Система/прочее}"
    [[ "$want_cpu" == "1" ]] || want_cpu=0
    [[ "$want_mem" == "1" ]] || want_mem=0
    [[ "$show_remainder" == "1" ]] || show_remainder=0

    local snapshot='' cpu_rows='' mem_rows=''
    local cpu_capacity='' total_memory_kib='' system_cpu_load_pct='0.0000'
    local cpu_json='[]' mem_json='[]'

    if [[ "$want_cpu" == "1" || "$want_mem" == "1" ]]; then
        snapshot="$(get_process_snapshot "$want_cpu")"
    fi
    if [[ "$want_cpu" == "1" ]]; then
        if [[ "$show_remainder" == "1" ]]; then
            cpu_rows="$(printf '%s\n' "$snapshot" | aggregate_process_rows cpu 4)"
        else
            cpu_rows="$(printf '%s\n' "$snapshot" | aggregate_process_rows cpu 5)"
        fi
        cpu_capacity="$(get_cpu_capacity_percent)"
        if [[ "$show_remainder" == "1" ]]; then
            if [[ -n "$snapshot" ]]; then
                system_cpu_load_pct="$(get_system_cpu_load_percent)"
            else
                system_cpu_load_pct='0.0000'
            fi
            cpu_rows="$(add_system_cpu_remainder_row "$cpu_rows" "$system_cpu_load_pct" "$cpu_capacity" "$remainder_label")"
        fi
        cpu_json="$(format_top_apps_rows_json "$cpu_rows" cpu "$cpu_capacity")"
    fi

    if [[ "$want_mem" == "1" ]]; then
        mem_rows="$(printf '%s\n' "$snapshot" | aggregate_process_rows mem)"
        total_memory_kib="$(get_total_memory_kib)"
        mem_json="$(format_top_apps_rows_json "$mem_rows" mem "$total_memory_kib")"
    fi

    jq -cn --argjson cpu "$cpu_json" --argjson mem "$mem_json" '{cpu:$cpu,mem:$mem}'
}
