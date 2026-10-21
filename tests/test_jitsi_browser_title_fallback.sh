#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
mkdir -p "$TMP_DIR/bin" "$TMP_DIR/runtime" "$TMP_DIR/config" "$TMP_DIR/data" "$TMP_DIR/state" "$TMP_DIR/cache" "$TMP_DIR/home"
export PATH="$TMP_DIR/bin:$PATH"
export HOME="$TMP_DIR/home"
export XDG_RUNTIME_DIR="$TMP_DIR/runtime"
export XDG_CONFIG_HOME="$TMP_DIR/config"
export XDG_DATA_HOME="$TMP_DIR/data"
export XDG_STATE_HOME="$TMP_DIR/state"
export XDG_CACHE_HOME="$TMP_DIR/cache"

cat > "$TMP_DIR/bin/playerctl" <<'STUB'
#!/bin/bash
if [[ "${1:-}" == "-l" ]]; then
    printf 'plasma-browser-integration\n'
    exit 0
fi
if [[ "${1:-}" == "-p" && "${2:-}" == "plasma-browser-integration" && "${3:-}" == "metadata" ]]; then
    if [[ "${5:-}" == '{{ mpris:artUrl }}' ]]; then
        printf '%s' "${MPRIS_ART:-}"
    else
        printf '%s\n' "${MPRIS_BROWSER:-}"
    fi
    exit 0
fi
exit 1
STUB
chmod +x "$TMP_DIR/bin/playerctl"

# Active Jitsi call: the room name is retained, the generic application
# suffix is removed, and the centered fallback label is not "silence".
export MPRIS_BROWSER=$'Playing\x1fTeamf | Jitsi Meet\x1f\x1f1000000\x1f0\x1f\x1f\x1fhttps://talk.sima-team.ru/teamf'
output="$("$ROOT/scripts/player" --priority plasma-browser-integration)"
jq -e '.player == "plasma-browser-integration" and .first_line == "Teamf" and .text == "Teamf"' <<< "$output" >/dev/null || {
    printf 'Jitsi room label was not normalized. JSON: %s\n' "$output" >&2
    exit 1
}

# Talk MPRIS titles use a distinct " | Talk" suffix; strip it and expose
# the room name as the fallback text instead of the generic silence label.
export MPRIS_BROWSER=$'Playing\x1fTeamf | Talk\x1f\x1f1000000\x1f0\x1f\x1f\x1fhttps://talk.sima-team.ru/teamf'
output="$("$ROOT/scripts/player" --priority plasma-browser-integration)"
jq -e '.player == "plasma-browser-integration" and .first_line == "Teamf" and .text == "Teamf"' <<< "$output" >/dev/null || {
    printf 'Talk room label was not normalized. JSON: %s\n' "$output" >&2
    exit 1
}

# When the browser title is the generic "silence | Talk" label, recover the
# room name from the URL, which is the useful label for this active call.
export MPRIS_BROWSER=$'Playing\x1fsilence | Talk\x1f\x1f1000000\x1f0\x1f\x1f\x1fhttps://talk.sima-team.ru/teamf'
output="$("$ROOT/scripts/player" --priority plasma-browser-integration)"
jq -e '.first_line == "teamf" and .text == "teamf"' <<< "$output" >/dev/null || {
    printf 'Talk silence-title fallback was not applied. JSON: %s\n' "$output" >&2
    exit 1
}


# Some browser builds return the generic fallback label with no suffix at all.
# The Talk URL is still enough to recover the room name.
export MPRIS_BROWSER=$'Playing\x1fsilence\x1f\x1f1000000\x1f0\x1f\x1f\x1fhttps://talk.sima-team.ru/teamf'
output="$("$ROOT/scripts/player" --priority plasma-browser-integration)"
jq -e '.first_line == "teamf" and .text == "teamf"' <<< "$output" >/dev/null || {
    printf 'Bare silence title on Talk URL was not normalized. JSON: %s\n' "$output" >&2
    exit 1
}

# Treat an unavailable/empty title similarly while the Talk host is known.
# This guards the early metadata validation that previously could return before
# the URL-based fallback had a chance to run.
export MPRIS_BROWSER=$'Playing\x1f\x1f\x1f1000000\x1f0\x1f\x1f\x1fhttps://talk.sima-team.ru/teamf'
output="$("$ROOT/scripts/player" --priority plasma-browser-integration)"
jq -e '.first_line == "teamf" and .text == "teamf"' <<< "$output" >/dev/null || {
    printf 'Empty title on Talk URL was not normalized. JSON: %s\n' "$output" >&2
    exit 1
}

# The alternate generic Jitsi suffix must not leak through as "silence" either.
export MPRIS_BROWSER=$'Playing\x1fsilence | Jitsi Meet\x1f\x1f1000000\x1f0\x1f\x1f\x1fhttps://talk.sima-team.ru/teamf'
output="$("$ROOT/scripts/player" --priority plasma-browser-integration)"
jq -e '.first_line == "teamf" and .text == "teamf"' <<< "$output" >/dev/null || {
    printf 'Jitsi silence-title fallback was not applied. JSON: %s\n' "$output" >&2
    exit 1
}

# A Jitsi title without a room name falls back to the final URL path segment.
export MPRIS_BROWSER=$'Playing\x1fJitsi Meet\x1f\x1f1000000\x1f0\x1f\x1f\x1fhttps://talk.sima-team.ru/teamf'
output="$("$ROOT/scripts/player" --priority plasma-browser-integration)"
jq -e '.first_line == "teamf" and .text == "teamf"' <<< "$output" >/dev/null || {
    printf 'Jitsi URL room fallback was not applied. JSON: %s\n' "$output" >&2
    exit 1
}

# Ordinary browser media remains unchanged and does not acquire the Jitsi label.
export MPRIS_BROWSER=$'Playing\x1fBrowser Track\x1fBrowser Artist\x1f1000000\x1f60000000\x1f00:59\x1f\x1fhttps://example.com/video'
output="$("$ROOT/scripts/player" --priority plasma-browser-integration)"
jq -e '.first_line == "Browser Track" and .text == "no image"' <<< "$output" >/dev/null || {
    printf 'Non-Jitsi browser metadata behavior changed. JSON: %s\n' "$output" >&2
    exit 1
}

printf 'Jitsi browser title fallback: OK\n'
