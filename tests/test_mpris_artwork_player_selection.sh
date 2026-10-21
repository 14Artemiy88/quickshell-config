#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
mkdir -p "$TMP_DIR/bin" "$TMP_DIR/runtime"
export XDG_RUNTIME_DIR="$TMP_DIR/runtime"
export XDG_CONFIG_HOME="$TMP_DIR/config"
export XDG_DATA_HOME="$TMP_DIR/data"
export XDG_STATE_HOME="$TMP_DIR/state"
export XDG_CACHE_HOME="$TMP_DIR/cache"
export PLAYERCTL_CALLS_LOG="$TMP_DIR/playerctl-calls.log"
export CURL_URL_LOG="$TMP_DIR/curl-urls.log"
export PATH="$TMP_DIR/bin:$PATH"

cat > "$TMP_DIR/bin/playerctl" <<'STUB'
#!/bin/bash
printf '%s\n' "$*" >> "$PLAYERCTL_CALLS_LOG"
if [[ "${1:-}" == "-p" && "${3:-}" == "metadata" && "${4:-}" == "-f" && "${5:-}" == "{{ mpris:artUrl }}" ]]; then
    case "$2" in
        spotify) printf '%s\n' 'https://art.example/spotify/cover.jpg' ;;
        plasma-browser-integration) printf '%s\n' 'https://art.example/browser/cover.jpg' ;;
        *) printf '%s\n' 'https://art.example/unexpected/cover.jpg' ;;
    esac
elif [[ "${1:-}" == "metadata" ]]; then
    printf '%s\n' 'https://art.example/unqualified/wrong-player.jpg'
else
    exit 1
fi
STUB

cat > "$TMP_DIR/bin/curl" <<'STUB'
#!/bin/bash
output=""
url=""
while (($#)); do
    case "$1" in
        --output|-o) output="$2"; shift 2 ;;
        *) url="$1"; shift ;;
    esac
done
printf '%s\n' "$url" >> "$CURL_URL_LOG"
[[ -n "$output" && -n "$url" ]] || exit 2
printf 'fake-image:%s\n' "$url" > "$output"
STUB

cat > "$TMP_DIR/bin/mogrify" <<'STUB'
#!/bin/bash
input="${@: -1}"
[[ -s "$input" ]] || exit 2
printf 'fake-png:%s\n' "$(cat "$input")" > "${input%.*}.png"
STUB
chmod +x "$TMP_DIR/bin/playerctl" "$TMP_DIR/bin/curl" "$TMP_DIR/bin/mogrify"

source "$ROOT/scripts/player.d/common.sh"

spotify_image="$(get_image '' spotify)"
browser_image="$(get_image '' plasma-browser-integration)"
[[ -s "$spotify_image" && -s "$browser_image" ]] || { echo 'selected-player artwork fallback was not cached' >&2; exit 1; }
[[ "$spotify_image" != "$browser_image" ]] || { echo 'different MPRIS players incorrectly shared artwork cache entry' >&2; exit 1; }

grep -Fxq -- '-p spotify metadata -f {{ mpris:artUrl }}' "$PLAYERCTL_CALLS_LOG" || {
    echo 'artUrl fallback did not query the explicitly selected Spotify player' >&2; exit 1;
}
grep -Fxq -- '-p plasma-browser-integration metadata -f {{ mpris:artUrl }}' "$PLAYERCTL_CALLS_LOG" || {
    echo 'artUrl fallback did not query the explicitly selected browser player' >&2; exit 1;
}
if grep -Fxq -- 'metadata -f {{ mpris:artUrl }}' "$PLAYERCTL_CALLS_LOG"; then
    echo 'selected-player lookup unexpectedly issued an unqualified playerctl request' >&2
    exit 1
fi
grep -Fxq 'https://art.example/spotify/cover.jpg' "$CURL_URL_LOG" || { echo 'Spotify cover URL was not used' >&2; exit 1; }
grep -Fxq 'https://art.example/browser/cover.jpg' "$CURL_URL_LOG" || { echo 'browser cover URL was not used' >&2; exit 1; }

# Guard the integration point: the MPRIS backend must forward its selected ID.
grep -Fq 'image=$(get_image "$img" "$player")' "$ROOT/scripts/player.d/backend_mpris.sh" || {
    echo 'MPRIS backend no longer forwards its selected player to artwork fallback' >&2; exit 1;
}

printf 'MPRIS artwork player selection: OK\n'
