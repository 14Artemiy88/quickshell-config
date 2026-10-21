#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
/bin/mkdir -p "$TMP_DIR/bin" "$TMP_DIR/home" "$TMP_DIR/cache" "$TMP_DIR/runtime/desktop-shell-player" \
    "$TMP_DIR/config/quickshell-widgets" "$TMP_DIR/data/quickshell-widgets" \
    "$TMP_DIR/state/quickshell-widgets" "$TMP_DIR/cache/quickshell-widgets"
export HOME="$TMP_DIR/home"
export XDG_CACHE_HOME="$TMP_DIR/cache" XDG_RUNTIME_DIR="$TMP_DIR/runtime"
export XDG_CONFIG_HOME="$TMP_DIR/config" XDG_DATA_HOME="$TMP_DIR/data" XDG_STATE_HOME="$TMP_DIR/state"
export QS_PROJECT_DIR="$ROOT" QS_CONFIG_DIR="$TMP_DIR/config/quickshell-widgets"
export QS_DATA_DIR="$TMP_DIR/data/quickshell-widgets" QS_STATE_DIR="$TMP_DIR/state/quickshell-widgets"
export QS_CACHE_DIR="$TMP_DIR/cache/quickshell-widgets"
export MPRIS_MKDIR_LOG="$TMP_DIR/mkdir-calls" CURL_FAIL=1
# Keep env sourcing quiet: destinations already exist and canonical settings
# files suppress legacy migration directory creation.
printf '{}\n' > "$QS_CONFIG_DIR/settings.json"
printf '{}\n' > "$QS_DATA_DIR/calendar-notes.json"

cat > "$TMP_DIR/bin/mkdir" <<'STUB'
#!/usr/bin/env bash
printf 'mkdir\n' >> "$MPRIS_MKDIR_LOG"
exec /bin/mkdir "$@"
STUB
cat > "$TMP_DIR/bin/curl" <<'STUB'
#!/usr/bin/env bash
exit 28
STUB
chmod +x "$TMP_DIR/bin/mkdir" "$TMP_DIR/bin/curl"
export PATH="$TMP_DIR/bin:$PATH"
source "$ROOT/scripts/player.d/common.sh"

url='https://cdn.example/warm-cache/cover.jpg?release=1'
digest="$(printf '%s' "$url" | sha256sum)"
key="${digest%% *}"
key="${key:0:32}"
image_path="$IMG_PATH/mpris-art-${key}.png"
printf 'MOCK_PNG\n' > "$image_path"
: > "$MPRIS_MKDIR_LOG"

for _ in {1..8}; do
    result="$(get_image "$url")"
    [[ "$result" == "$image_path" ]] || { echo 'warm cache path changed' >&2; exit 1; }
done
[[ ! -s "$MPRIS_MKDIR_LOG" ]] || { echo 'warm cache hit launched mkdir' >&2; exit 1; }

# Cache misses still create the runtime directory before opening the lock and
# attempting a download. A failed fetch must keep the existing fallback.
missing_url='https://cdn.example/cache-miss/cover.jpg'
: > "$MPRIS_MKDIR_LOG"
result="$(get_image "$missing_url")"
[[ "$result" == "$DEFAULT_IMG" ]] || { echo 'failed cache-miss fetch did not return default image' >&2; exit 1; }
[[ "$(wc -l < "$MPRIS_MKDIR_LOG")" -eq 1 ]] || { echo 'cache miss should create/check the runtime directory exactly once' >&2; exit 1; }

# Unsupported schemes must still return immediately without directory access.
: > "$MPRIS_MKDIR_LOG"
result="$(get_image 'ftp://cdn.example/not-supported.png')"
[[ "$result" == "$DEFAULT_IMG" ]] || { echo 'unsupported scheme did not return default image' >&2; exit 1; }
[[ ! -s "$MPRIS_MKDIR_LOG" ]] || { echo 'unsupported scheme unexpectedly invoked mkdir' >&2; exit 1; }

printf 'MPRIS artwork warm-cache path skips mkdir: OK\n'
