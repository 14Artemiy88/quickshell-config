#!/bin/bash

get_top_apps() {
    local -a cpu_entries=() mem_entries=()
    local line pid pcpu rss comm i v

    while IFS= read -r line && (( ${#cpu_entries[@]} < 5 )); do
        read -r pid pcpu comm <<< "$line"
        [[ -z "$pid" ]] && break
        cpu_entries+=("{\"name\":\"$comm\",\"value\":\"$pcpu%\",\"pid\":\"$pid\"}")
    done < <(ps --no-header -eo pid,pcpu,comm --sort=-pcpu | head -5)

    while IFS= read -r line && (( ${#mem_entries[@]} < 5 )); do
        read -r pid rss comm <<< "$line"
        [[ -z "$pid" ]] && break
        v=$rss
        if (( v >= 1048576 )); then v="$(LC_NUMERIC=C bc <<< "scale=1; $v/1048576") Gb"
        elif (( v >= 1024 )); then v="$(LC_NUMERIC=C bc <<< "scale=1; $v/1024") Mb"
        else v="$v Kb"
        fi
        mem_entries+=("{\"name\":\"$comm\",\"value\":\"$v\",\"pid\":\"$pid\"}")
    done < <(ps --no-header -eo pid,rss,comm --sort=-rss | head -5)

    local cjson="" mjson=""
    for ((i=0; i<${#cpu_entries[@]}; i++)); do
        [[ -n "$cjson" ]] && cjson="$cjson,"
        cjson="${cjson}${cpu_entries[i]}"
    done
    for ((i=0; i<${#mem_entries[@]}; i++)); do
        [[ -n "$mjson" ]] && mjson="$mjson,"
        mjson="${mjson}${mem_entries[i]}"
    done
    printf '{"cpu":[%s],"mem":[%s]}' "$cjson" "$mjson"
}
