#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
mkdir -p "$TMP_DIR/bin" "$TMP_DIR/runtime" "$TMP_DIR/config" "$TMP_DIR/data" "$TMP_DIR/state" "$TMP_DIR/cache"
export PATH="$TMP_DIR/bin:$PATH"
export XDG_RUNTIME_DIR="$TMP_DIR/runtime"
export XDG_CONFIG_HOME="$TMP_DIR/config"
export XDG_DATA_HOME="$TMP_DIR/data"
export XDG_STATE_HOME="$TMP_DIR/state"
export XDG_CACHE_HOME="$TMP_DIR/cache"
export PLAYERCTL_CALL_LOG="$TMP_DIR/playerctl.log"
export PLAYERCTL_LIST_MODE=ok

cat > "$TMP_DIR/bin/playerctl" <<'STUB'
#!/bin/bash
printf '%s\n' "$*" >> "$PLAYERCTL_CALL_LOG"
if [[ "${1:-}" == "-l" ]]; then
    [[ "${PLAYERCTL_LIST_MODE:-ok}" == "ok" ]] || exit 1
    printf 'spotify\nplasma-browser-integration\norg.telegram.desktop\nspotify.extra\n'
    exit 0
fi
exit 1
STUB
chmod +x "$TMP_DIR/bin/playerctl"

# A single playerctl inventory should service several exact membership checks.
bash -c '
    source "$1"
    mpris_player_is_active spotify
    mpris_player_is_active plasma-browser-integration
    mpris_player_is_active org.telegram.desktop
    mpris_player_is_active spotify.extra
    ! mpris_player_is_active spotify-extra
' _ "$ROOT/scripts/player.d/backend_mpris.sh"

list_calls=$(grep -c '^-l$' "$PLAYERCTL_CALL_LOG" || true)
[[ "$list_calls" -eq 1 ]] || {
    echo "Expected one playerctl -l call for five membership checks; got $list_calls" >&2
    cat "$PLAYERCTL_CALL_LOG" >&2
    exit 1
}

# An unavailable playerctl inventory is cached within the same invocation too,
# so a DBus/startup failure does not launch playerctl repeatedly for each ID.
: > "$PLAYERCTL_CALL_LOG"
PLAYERCTL_LIST_MODE=fail bash -c '
    source "$1"
    ! mpris_player_is_active spotify
    ! mpris_player_is_active plasma-browser-integration
    ! mpris_player_is_active org.telegram.desktop
' _ "$ROOT/scripts/player.d/backend_mpris.sh"
list_calls=$(grep -c '^-l$' "$PLAYERCTL_CALL_LOG" || true)
[[ "$list_calls" -eq 1 ]] || {
    echo "Expected one failed playerctl -l call to be cached; got $list_calls" >&2
    exit 1
}

# Guard the cache to one script invocation: a fresh process must start with an
# unloaded cache and still query playerctl itself.
: > "$PLAYERCTL_CALL_LOG"
bash -c 'source "$1"; mpris_player_is_active spotify' _ "$ROOT/scripts/player.d/backend_mpris.sh"
list_calls=$(grep -c '^-l$' "$PLAYERCTL_CALL_LOG" || true)
[[ "$list_calls" -eq 1 ]] || {
    echo "Expected fresh invocation to load player list; got $list_calls" >&2
    exit 1
}

echo 'MPRIS active-player inventory cache: OK'
