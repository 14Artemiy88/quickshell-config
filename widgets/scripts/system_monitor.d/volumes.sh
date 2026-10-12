#!/bin/bash

get_volumes() {
    local num vol name
    local -a items=()

    # pactl's human-readable headings may be localized. Accept the common
    # English and Russian forms while preserving arbitrary stream names via
    # NUL-delimited records between awk and Bash.
    while IFS= read -r -d '' num && IFS= read -r -d '' vol && IFS= read -r -d '' name; do
        [[ "$num" =~ ^[0-9]+$ && "$vol" =~ ^[0-9]+([.][0-9]+)?$ ]] || continue
        # jq handles quotes, backslashes and control characters in names.
        items+=("$(jq -cn --arg num "$num" --arg value "$vol" --arg name "$name" '{num:$num,value:$value,name:$name}')")
    done < <(pactl list sink-inputs 2>/dev/null | awk '
        function extract_media_name(line, pos, i, c, result, escaped) {
            pos = index(line, "media.name = \"")
            if (!pos) return ""
            i = pos + length("media.name = \"")
            result = ""
            escaped = 0
            for (; i <= length(line); i++) {
                c = substr(line, i, 1)
                if (escaped) {
                    # pactl escapes properties in a C-like representation.
                    # Keep escaped line breaks as spaces so they cannot split
                    # the record framing; decode escaped quotes/backslashes.
                    if (c == "n" || c == "r" || c == "t") result = result " "
                    else result = result c
                    escaped = 0
                } else if (c == "\\") {
                    escaped = 1
                } else if (c == "\"") {
                    break
                } else {
                    result = result c
                }
            }
            return result
        }
        function emit_record() {
            if (num != "" && vol != "" && got_name) {
                printf "%s%c%s%c%s%c", num, 0, vol, 0, name, 0
            }
        }
        /Sink Input #[0-9]+|Вход аудиоприёмника №[0-9]+/ {
            emit_record()
            num = $0
            if (num ~ /№/) sub(/.*№/, "", num)
            else sub(/.*#/, "", num)
            vol = ""; name = ""; got_name = 0
        }
        /(Volume:|Громкость:)/ {
            if (vol == "") {
                count = split($0, p, " ")
                for (i = 1; i <= count; i++) {
                    if (p[i] ~ /^[0-9]+([.][0-9]+)?%$/) {
                        vol = p[i]
                        sub(/%$/, "", vol)
                        break
                    }
                }
            }
        }
        /media.name =/ {
            parsed = extract_media_name($0)
            if (!got_name && parsed != "") {
                name = parsed
                got_name = 1
            }
        }
        END { emit_record() }
    ')

    if ((${#items[@]} > 0)); then
        printf '%s\n' "${items[@]}" | jq -s '.'
    else
        printf '[]'
    fi
}
