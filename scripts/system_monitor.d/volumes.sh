#!/bin/bash

# Escape a string for JSON without launching jq for this collector's final
# encoding. Operates bytewise so UTF-8 bytes pass through unchanged while ASCII
# control bytes are escaped as required by JSON. Bash cannot store NUL bytes.
system_monitor_volume_json_escape_into() {
    local output_var="${1:-}" value="${2-}" char escaped_char out="" i code
    [[ "$output_var" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] || return 2
    local LC_ALL=C
    for ((i = 0; i < ${#value}; i++)); do
        char="${value:i:1}"
        case "$char" in
            $'\\') out+='\\' ;;
            '"') out+='\"' ;;
            $'\b') out+='\b' ;;
            $'\f') out+='\f' ;;
            $'\n') out+='\n' ;;
            $'\r') out+='\r' ;;
            $'\t') out+='\t' ;;
            *)
                printf -v code '%d' "'$char"
                if (( code < 32 || code == 127 )); then
                    printf -v escaped_char '\\u%04x' "$code"
                    out+="$escaped_char"
                else
                    out+="$char"
                fi
                ;;
        esac
    done
    printf -v "$output_var" '%s' "$out"
}

# Turn a flat sequence of num/value/name triples into the existing JSON array.
# Arguments preserve row boundaries and Bash handles escaping without jq.
system_monitor_volume_encode_fields() {
    local -a fields=("$@")
    if ((${#fields[@]} == 0)); then
        printf '[]'
        return 0
    fi

    (( ${#fields[@]} % 3 == 0 )) || return 2
    local json='[' first=1 i num_json value_json name_json
    for ((i = 0; i < ${#fields[@]}; i += 3)); do
        system_monitor_volume_json_escape_into num_json "${fields[i]}" || return 1
        system_monitor_volume_json_escape_into value_json "${fields[i + 1]}" || return 1
        system_monitor_volume_json_escape_into name_json "${fields[i + 2]}" || return 1
        (( first )) || json+=','
        first=0
        json+="{\"num\":\"${num_json}\",\"value\":\"${value_json}\",\"name\":\"${name_json}\"}"
    done
    json+=']'
    printf '%s\n' "$json"
}

get_volumes() {
    local num vol name
    # Preserve arbitrary user-facing names as independent fields, then encode
    # them in Bash after AWK parsing to avoid a per-poll jq process.
    local -a fields=()

    # pactl's human-readable headings may be localized. Accept the common
    # English and Russian forms while preserving arbitrary stream names via
    # NUL-delimited records between awk and Bash.
    while IFS= read -r -d '' num && IFS= read -r -d '' vol && IFS= read -r -d '' name; do
        [[ "$num" =~ ^[0-9]+$ && "$vol" =~ ^[0-9]+([.][0-9]+)?$ ]] || continue
        # Keep the original parsed values; the JSON escaper below owns quoting.
        fields+=("$num" "$vol" "$name")
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

    # The main System Monitor process validates the complete payload in its
    # final jq assembly pass. Keep this collector process-free after AWK by
    # encoding its parsed fields with the byte-safe Bash JSON escaper.
    system_monitor_volume_encode_fields "${fields[@]}"
}
