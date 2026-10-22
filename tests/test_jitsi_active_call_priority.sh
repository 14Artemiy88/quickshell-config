#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
mkdir -p "$TMP_DIR/bin" "$TMP_DIR/runtime" "$TMP_DIR/config" "$TMP_DIR/data" "$TMP_DIR/state" "$TMP_DIR/cache" "$TMP_DIR/home"
export PATH="$TMP_DIR/bin:$PATH" HOME="$TMP_DIR/home"
export XDG_RUNTIME_DIR="$TMP_DIR/runtime" XDG_CONFIG_HOME="$TMP_DIR/config" XDG_DATA_HOME="$TMP_DIR/data" XDG_STATE_HOME="$TMP_DIR/state" XDG_CACHE_HOME="$TMP_DIR/cache"
cat > "$TMP_DIR/bin/playerctl" <<'STUB'
#!/bin/bash
if [[ "${1:-}" == "-l" ]]; then
    printf 'spotify\nplasma-browser-integration\n'
    exit 0
fi
if [[ "${1:-}" == "-p" && "${3:-}" == "metadata" ]]; then
    player="$2"
    format="${5:-}"
    if [[ "$format" == '{{ mpris:artUrl }}' ]]; then exit 0; fi
    if [[ "$player" == "plasma-browser-integration" ]]; then
        printf '%s\n' "$MPRIS_BROWSER"
    else
        printf '%s\n' "$MPRIS_SPOTIFY"
    fi
    exit 0
fi
exit 1
STUB
chmod +x "$TMP_DIR/bin/playerctl"
# A paused Spotify service appears earlier in the configured order, but must not mask an active Jitsi call.
export MPRIS_SPOTIFY=$'Paused\x1fSpotify track\x1fArtist\x1f0\x1f60000000\x1f-01:00\x1f\x1fhttps://open.spotify.com/track/test'
export MPRIS_BROWSER=$'Playing\x1fTeamf | Jitsi Meet\x1f\x1f1000000\x1f0\x1f\x1f\x1fhttps://talk.sima-team.ru/teamf'
output="$("$ROOT/scripts/player" --priority spotify plasma-browser-integration)"
jq -e '.player == "plasma-browser-integration" and .first_line == "Teamf" and .text == "Teamf"' <<< "$output" >/dev/null || {
    printf 'Active Jitsi call was masked by a paused higher-priority player. JSON: %s\n' "$output" >&2
    exit 1
}
printf 'Jitsi active-call priority over paused MPRIS source: OK\n'
