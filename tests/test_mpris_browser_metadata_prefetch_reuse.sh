#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf -- "$TMP_DIR"' EXIT
mkdir -p "$TMP_DIR/bin" "$TMP_DIR/runtime" "$TMP_DIR/config" "$TMP_DIR/data" "$TMP_DIR/state" "$TMP_DIR/cache" "$TMP_DIR/home" \
    "$TMP_DIR/runtime/desktop-shell-player"
export PATH="$TMP_DIR/bin:$PATH" HOME="$TMP_DIR/home"
export XDG_RUNTIME_DIR="$TMP_DIR/runtime" XDG_CONFIG_HOME="$TMP_DIR/config" XDG_DATA_HOME="$TMP_DIR/data" XDG_STATE_HOME="$TMP_DIR/state" XDG_CACHE_HOME="$TMP_DIR/cache"
export QS_PROJECT_DIR="$ROOT" PLAYERCTL_QUERY_LOG="$TMP_DIR/playerctl-queries.log"

cat > "$TMP_DIR/bin/playerctl" <<'STUB'
#!/usr/bin/env bash
if [[ "${1:-}" == "-l" ]]; then
    printf 'spotify\nplasma-browser-integration\n'
    exit 0
fi
if [[ "${1:-}" == "-p" && "${3:-}" == "metadata" ]]; then
    player="$2"
    format="${5:-}"
    if [[ "$format" == '{{ mpris:artUrl }}' ]]; then
        printf '%s' "${ART_URL:-}"
        exit 0
    fi
    printf '%s\tmetadata\n' "$player" >> "$PLAYERCTL_QUERY_LOG"
    case "$player" in
        plasma-browser-integration) printf '%s\n' "$MPRIS_BROWSER" ;;
        spotify) printf '%s\n' "$MPRIS_SPOTIFY" ;;
        *) exit 1 ;;
    esac
    exit 0
fi
exit 1
STUB
chmod +x "$TMP_DIR/bin/playerctl"

# Prime the regular artwork cache so this test measures metadata probes only,
# not get_image's separate missing-art fallback request.
export ART_URL='https://cdn.example/prefetch-regression-cover.jpg'
digest="$(printf '%s' "$ART_URL" | sha256sum)"
digest="${digest%% *}"
printf 'cached-image\n' > "$TMP_DIR/runtime/desktop-shell-player/mpris-art-${digest:0:32}.png"

count_browser_metadata_queries() {
    awk -F '\t' '$1 == "plasma-browser-integration" && $2 == "metadata" { count++ } END { print count + 0 }' "$PLAYERCTL_QUERY_LOG"
}

# Ordinary browser media is preflighted and then selected by the normal loop.
# The full response should be shared, instead of launching playerctl twice.
export MPRIS_SPOTIFY=$'Paused\x1fSpotify track\x1fArtist\x1f0\x1f60000000\x1f-01:00\x1f\x1fhttps://open.spotify.com/track/test'
export MPRIS_BROWSER="Playing"$'\x1f'"Browser Track"$'\x1f'"Browser Artist"$'\x1f'"1000000"$'\x1f'"60000000"$'\x1f'"-00:59"$'\x1f'"$ART_URL"$'\x1f'"https://open.spotify.com/track/test"
: > "$PLAYERCTL_QUERY_LOG"
output="$("$ROOT/scripts/player" --priority plasma-browser-integration)"
jq -e '.player == "plasma-browser-integration" and .first_line == "Browser Track"' <<< "$output" >/dev/null
queries="$(count_browser_metadata_queries)"
[[ "$queries" -eq 1 ]] || {
    printf 'Expected one browser metadata query for ordinary media; got %s\n%s\n' "$queries" "$output" >&2
    cat "$PLAYERCTL_QUERY_LOG" >&2
    exit 1
}

# A playing Jitsi call must still outrank a paused Spotify service, and should
# use the same prefetched response when its metadata is serialized.
export MPRIS_BROWSER="Playing"$'\x1f'"Teamf | Jitsi Meet"$'\x1f'""$'\x1f'"1000000"$'\x1f'"60000000"$'\x1f'"-00:59"$'\x1f'"$ART_URL"$'\x1f'"https://talk.sima-team.ru/teamf"
: > "$PLAYERCTL_QUERY_LOG"
output="$("$ROOT/scripts/player" --priority spotify plasma-browser-integration)"
jq -e '.player == "plasma-browser-integration" and .first_line == "Teamf" and .text == "Teamf"' <<< "$output" >/dev/null
queries="$(count_browser_metadata_queries)"
[[ "$queries" -eq 1 ]] || {
    printf 'Expected one browser metadata query for Jitsi priority; got %s\n%s\n' "$queries" "$output" >&2
    cat "$PLAYERCTL_QUERY_LOG" >&2
    exit 1
}

printf 'MPRIS browser metadata prefetch reuse: OK\n'
