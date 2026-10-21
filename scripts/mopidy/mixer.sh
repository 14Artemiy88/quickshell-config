#!/bin/bash
set -euo pipefail

MOPIDY_RPC_URL="${MOPIDY_RPC_URL:-http://localhost:6680/mopidy/rpc}"
SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_DIR="${SCRIPT_PATH%/*}"
[[ "$SCRIPT_DIR" != "$SCRIPT_PATH" ]] || SCRIPT_DIR=.
source "$SCRIPT_DIR/pulse_mixer.sh"

rpc() {
    local method="$1"
    local params="{}"
    [[ -n "${2:-}" ]] && params="$2"
    curl -sS --connect-timeout 1 --max-time 3 \
        -H 'Content-Type: application/json' \
        -d "$(jq -cn --argjson params "$params" --arg method "$method" '{jsonrpc:"2.0",id:1,method:$method,params:$params}')" \
        "$MOPIDY_RPC_URL" 2>/dev/null
}

mopidy_state_dir() {
    printf '%s\n' "${QS_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/quickshell-widgets}"
}

read_restore_volume() {
    local path value=""
    path="$(mopidy_state_dir)/mopidy-volume-restore"
    [[ -r "$path" ]] && IFS= read -r value < "$path" || true
    if [[ "$value" =~ ^[0-9]+$ ]] && (( value >= 1 && value <= 100 )); then
        printf '%s\n' "$value"
    fi
}

save_restore_volume() {
    local value="${1:-}" state_dir path tmp
    [[ "$value" =~ ^[0-9]+$ ]] && (( value >= 1 && value <= 100 )) || return 0
    state_dir="$(mopidy_state_dir)"
    path="$state_dir/mopidy-volume-restore"
    mkdir -p -- "$state_dir" 2>/dev/null || return 0
    tmp=$(mktemp "$state_dir/.mopidy-volume-restore.XXXXXX") || return 0
    if ! printf '%s\n' "$value" > "$tmp"; then
        rm -f -- "$tmp"
        return 0
    fi
    mv -f -- "$tmp" "$path" 2>/dev/null || rm -f -- "$tmp"
}

get_mixer() {
    local response normalized pulse_mute
    # These are independent read-only state queries. Batch them into one HTTP
    # request, matching the polling strategy used by mopidy/status.sh. The
    # previous implementation made two curl requests, spawned jq to build each
    # request, parsed each reply separately, then ran a final jq to assemble JSON.
    response=$(curl -sS --connect-timeout 1 --max-time 3 \
        -H 'Content-Type: application/json' \
        -d '[
            {"jsonrpc":"2.0","id":1,"method":"core.mixer.get_volume"},
            {"jsonrpc":"2.0","id":2,"method":"core.mixer.get_mute"}
        ]' \
        "$MOPIDY_RPC_URL" 2>/dev/null) || {
        printf '{"ok":false,"volume":null,"mute":null}\n'
        return 0
    }

    normalized=$(jq -c '
        def result($id):
            ([.[]? | select(.id == $id)][0] // {}) as $reply
            | if $reply.error? != null then null
              elif ($reply | has("result")) then $reply.result
              else null end;
        def has_output($value):
            if $value == null then false
            elif ($value | type) == "string" then $value != ""
            else true end;
        (result(1)) as $raw_volume
        | (if ((($raw_volume | type) == "number" or ($raw_volume | type) == "string") and
               (($raw_volume | tostring) | test("^[0-9]+$")))
           then (($raw_volume | tostring) | tonumber) else null end) as $volume
        | (result(2)) as $raw_mute
        | (if ($raw_mute | type) == "boolean" then $raw_mute
           elif ($raw_mute | type) == "string" and ($raw_mute == "true" or $raw_mute == "false")
           then ($raw_mute == "true") else null end) as $mute
        | if (has_output($raw_volume) or has_output($raw_mute)) then
            {ok:true,volume:$volume,mute:$mute}
          else
            {ok:false,volume:null,mute:null}
          end
    ' <<< "$response" 2>/dev/null) || {
        printf '{"ok":false,"volume":null,"mute":null}\n'
        return 0
    }

    pulse_mute="$(mopidy_pulse_get_mute 2>/dev/null || true)"
    if [[ "$pulse_mute" == "true" || "$pulse_mute" == "false" ]]; then
        jq -c --arg pulse_mute "$pulse_mute" \
            'if .mute == true then . else .mute = ($pulse_mute == "true") end' \
            <<< "$normalized" 2>/dev/null || printf '%s\n' "$normalized"
    else
        printf '%s\n' "$normalized"
    fi
}

set_volume() {
    local value="${1:-}" restore_hint="${2:-}"
    if [[ ! "$value" =~ ^[0-9]+$ ]]; then
        printf '{"ok":false,"error":"invalid-volume"}\n'
        return 2
    fi
    value=$(( value < 0 ? 0 : value > 100 ? 100 : value ))
    if (( value == 0 )); then
        save_restore_volume "$restore_hint"
    fi
    local response
    response=$(rpc 'core.mixer.set_volume' "$(jq -cn --argjson volume "$value" '{volume:$volume}')" || true)
    if (( value > 0 )) && jq -e '(.error // null) == null' <<< "$response" >/dev/null 2>&1; then
        save_restore_volume "$value"
    fi
    jq -c '{ok:(.error == null), result:(.result // null)}' <<<"$response" 2>/dev/null || printf '{"ok":false}\n'
}

set_mute() {
    local value="${1:-toggle}" restore_hint="${2:-}" current_mute="false" pulse_mute=""
    if [[ "$value" == "toggle" ]]; then
        pulse_mute="$(mopidy_pulse_get_mute 2>/dev/null || true)"
        if [[ "$pulse_mute" == "true" ]]; then
            value=false
        elif [[ "$pulse_mute" == "false" ]]; then
            value=true
        else
            current_mute=$(rpc 'core.mixer.get_mute' | jq -r '.result // false' 2>/dev/null || printf 'false')
            if [[ "$current_mute" == "true" ]]; then
                value=false
            else
                local current_volume
                current_volume=$(rpc 'core.mixer.get_volume' | jq -r '.result // 0' 2>/dev/null || printf '0')
                if [[ "$current_volume" =~ ^[0-9]+$ ]] && (( current_volume == 0 )); then value=false; else value=true; fi
                [[ "$restore_hint" =~ ^[0-9]+$ ]] || restore_hint="$current_volume"
            fi
        fi
    fi
    if [[ "$value" != "true" && "$value" != "false" ]]; then
        printf '{"ok":false,"error":"invalid-mute"}\n'
        return 2
    fi

    # Prefer a direct PulseAudio/PipeWire sink-input mute. Unlike Mopidy's
    # software mixer RPC, this command changes the actual playback stream
    # immediately. It leaves Mopidy's non-zero mixer level intact, so unmute
    # can also take effect instantly. If there is no identifiable sink input,
    # retain the RPC volume fallback for ALSA/other output backends.
    if [[ "$value" == "true" ]]; then
        if ! [[ "$restore_hint" =~ ^[0-9]+$ ]] || (( restore_hint < 1 || restore_hint > 100 )); then
            restore_hint="$(read_restore_volume || true)"
        fi
        if ! [[ "$restore_hint" =~ ^[0-9]+$ ]] || (( restore_hint < 1 || restore_hint > 100 )); then
            local current_volume
            current_volume=$(rpc 'core.mixer.get_volume' | jq -r '.result // 0' 2>/dev/null || printf '0')
            restore_hint="$current_volume"
        fi
        save_restore_volume "$restore_hint"
        if mopidy_pulse_set_mute true; then
            printf '{"ok":true,"mode":"pulse-stream","mute":true}\n'
            return 0
        fi

        # Fallback for Mopidy output backends that do not expose a PulseAudio
        # sink input, including direct ALSA output.
        set_volume 0 "$restore_hint"
        return $?
    fi

    local restore_volume native_mute mute_response response
    restore_volume="$restore_hint"
    if ! [[ "$restore_volume" =~ ^[0-9]+$ ]] || (( restore_volume < 1 || restore_volume > 100 )); then
        restore_volume="$(read_restore_volume || true)"
    fi
    if ! [[ "$restore_volume" =~ ^[0-9]+$ ]] || (( restore_volume < 1 || restore_volume > 100 )); then
        restore_volume=50
    fi
    save_restore_volume "$restore_volume"

    if mopidy_pulse_set_mute false; then
        # Unmute the Pulse stream first. If the previous build left Mopidy's
        # own software mixer at zero, restore it afterwards; audible output is
        # already re-enabled immediately and the same non-zero level is kept.
        # Keep the UI/action process non-blocking. In the regular path the
        # volume is already at restore_volume, so this request is a no-op for
        # audio and only synchronizes legacy software-mute state if necessary.
        # Redirect every descriptor so the detached sync cannot hold the
        # parent Process stdout/stderr collectors open.
        ( set_volume "$restore_volume" >/dev/null 2>&1 ) </dev/null >/dev/null 2>&1 &
        printf '{"ok":true,"mode":"pulse-stream","mute":false}\n'
        return 0
    fi

    # Fallback: no PulseAudio sink input was found. Restore volume through the
    # Mopidy mixer and clear a native mute from older versions if necessary.
    native_mute=$(rpc 'core.mixer.get_mute' | jq -r '.result // false' 2>/dev/null || printf 'false')
    if [[ "$native_mute" == "true" ]]; then
        mute_response=$(rpc 'core.mixer.set_mute' '{"mute":false}' || true)
        if jq -e '.error != null' <<< "$mute_response" >/dev/null 2>&1; then
            jq -c '{ok:false,error:(.error.message // "unmute-failed")}' <<< "$mute_response"
            return 1
        fi
    fi
    response=$(set_volume "$restore_volume")
    printf '%s\n' "$response"
}


migrate_soft_mute() {
    local restore_volume="${1:-}" native_mute mute_response response
    if ! [[ "$restore_volume" =~ ^[0-9]+$ ]] || (( restore_volume < 1 || restore_volume > 100 )); then
        restore_volume="$(read_restore_volume || true)"
    fi
    if ! [[ "$restore_volume" =~ ^[0-9]+$ ]] || (( restore_volume < 1 || restore_volume > 100 )); then
        restore_volume=50
    fi
    # Mute the Pulse stream before raising Mopidy's software mixer level, so a
    # legacy zero-volume mute remains silent throughout this one-time migration.
    if ! mopidy_pulse_set_mute true; then
        printf '{"ok":false,"error":"no-pulse-stream"}\n'
        return 1
    fi
    save_restore_volume "$restore_volume"
    native_mute="$(rpc 'core.mixer.get_mute' | jq -r '.result // false' 2>/dev/null || printf 'false')"
    if [[ "$native_mute" == "true" ]]; then
        mute_response="$(rpc 'core.mixer.set_mute' '{"mute":false}' || true)"
        if jq -e '.error != null' <<< "$mute_response" >/dev/null 2>&1; then
            jq -c '{ok:false,error:(.error.message // "native-unmute-failed")}' <<< "$mute_response"
            return 1
        fi
    fi
    response="$(set_volume "$restore_volume")"
    if jq -e '.ok == true' <<< "$response" >/dev/null 2>&1; then
        printf '{"ok":true,"mode":"pulse-migration","mute":true,"volume":%s}\n' "$restore_volume"
    else
        printf '{"ok":false,"mode":"pulse-migration","mute":true,"volume":%s}\n' "$restore_volume"
        return 1
    fi
}


diagnose_pulse() {
    local pactl_path records id muted app binary pid media_name app_l binary_l media_l cmd cmd_l matched count=0 matches=""
    pactl_path="$(command -v pactl 2>/dev/null || true)"
    printf 'pactl=%s\n' "${pactl_path:-missing}"
    if [[ -z "$pactl_path" ]]; then
        printf 'pulse_access=missing-pactl\n'
        return 1
    fi
    records="$(mopidy_pulse_parse_sink_inputs 2>/dev/null)" || {
        printf 'pulse_access=failed\n'
        return 1
    }
    if [[ -z "$records" ]]; then
        printf 'pulse_access=ok\nparsed_sink_inputs=0\nmopidy_matches=none\n'
        return 0
    fi
    while IFS=$'\034' read -r id muted app binary pid media_name; do
        [[ "$id" =~ ^[0-9]+$ ]] || continue
        ((count+=1))
        app_l="${app,,}"
        binary_l="${binary,,}"
        media_l="${media_name,,}"
        matched=no
        if [[ "$app_l" == *mopidy* || "$binary_l" == *mopidy* || "$media_l" == *mopidy* ]]; then
            matched=yes
        elif [[ "$pid" =~ ^[0-9]+$ ]]; then
            cmd="$(ps -p "$pid" -o args= 2>/dev/null || true)"
            cmd_l="${cmd,,}"
            [[ "$cmd_l" == *mopidy* ]] && matched=yes
        fi
        printf 'sink_input=%s mute=%s app=%q binary=%q pid=%q media_name=%q match=%s\n' \
            "$id" "${muted:-unknown}" "$app" "$binary" "$pid" "$media_name" "$matched"
        if [[ "$matched" == yes ]]; then
            matches+="${matches:+,}$id"
        fi
    done <<< "$records"
    printf 'pulse_access=ok\nparsed_sink_inputs=%s\nmopidy_matches=%s\n' "$count" "${matches:-none}"
    [[ -n "$matches" ]]
}

case "${1:-get}" in
    get) get_mixer ;;
    set) set_volume "${2:-}" "${3:-}" ;;
    mute) set_mute "${2:-toggle}" "${3:-}" ;;
    migrate-soft-mute) migrate_soft_mute "${2:-}" ;;
    diagnose-pulse) diagnose_pulse ;;
    *) echo "Usage: $0 {get|set <0-100>|mute [true|false|toggle]|migrate-soft-mute <1-100>|diagnose-pulse}" >&2; exit 1 ;;
esac
