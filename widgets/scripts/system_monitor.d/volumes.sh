#!/bin/bash

get_volumes() {
    local data num vol name items=()
    data=$(pactl list sink-inputs 2>/dev/null | awk '
        /Вход аудиоприёмника №[0-9]+/ {
            if (num != "" && vol != "" && name != "") {
                print num; print vol; print name
            }
            num = $0; sub(/.*№/, "", num)
            vol = ""; name = ""; reset = 1
        }
        /Громкость:/ && reset {
            split($0, p, " ")
            for (i in p) if (p[i] ~ /[0-9]+%/) { vol = p[i]; sub(/%/, "", vol); break }
        }
        /media.name =/ && reset {
            name = $0; sub(/.*media.name = "/, "", name); sub(/".*/, "", name); reset = 0
        }
        END { if (num != "" && vol != "" && name != "") { print num; print vol; print name } }
    ')

    if [[ -z "$data" ]]; then printf '[]'; return; fi

    local -a arr=()
    local i
    while IFS= read -r line; do arr+=("$line"); done <<< "$data"

    for ((i=0; i<${#arr[@]}; i+=3)); do
        num="${arr[i]}"; vol="${arr[i+1]}"; name="${arr[i+2]}"
        [[ -z "$num" || -z "$vol" || -z "$name" ]] && continue
        name="${name//\\/\\\\}"
        name="${name//\"/\\\"}"
        items+=("{\"num\":\"$num\",\"value\":\"$vol\",\"name\":\"$name\"}")
    done

    if (( ${#items[@]} > 0 )); then
        local json="${items[0]}"
        for ((i=1; i<${#items[@]}; i++)); do json="$json,${items[i]}"; done
        printf '[%s]' "$json"
    else
        printf '[]'
    fi
}
