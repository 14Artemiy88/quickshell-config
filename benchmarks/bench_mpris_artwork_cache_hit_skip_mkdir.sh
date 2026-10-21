#!/usr/bin/env bash
# Compare the former unconditional mkdir -p against the current warm-cache path.
set -euo pipefail
ROOT="$(cd -- "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ITERATIONS="${1:-100}"
TRIALS="${2:-5}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
/bin/mkdir -p "$TMP_DIR/bin" "$TMP_DIR/home" "$TMP_DIR/cache" "$TMP_DIR/runtime/desktop-shell-player" \
    "$TMP_DIR/config/quickshell-widgets" "$TMP_DIR/data/quickshell-widgets" \
    "$TMP_DIR/state/quickshell-widgets" "$TMP_DIR/cache/quickshell-widgets"
export HOME="$TMP_DIR/home" XDG_CACHE_HOME="$TMP_DIR/cache" XDG_RUNTIME_DIR="$TMP_DIR/runtime"
export XDG_CONFIG_HOME="$TMP_DIR/config" XDG_DATA_HOME="$TMP_DIR/data" XDG_STATE_HOME="$TMP_DIR/state"
export QS_PROJECT_DIR="$ROOT" QS_CONFIG_DIR="$TMP_DIR/config/quickshell-widgets"
export QS_DATA_DIR="$TMP_DIR/data/quickshell-widgets" QS_STATE_DIR="$TMP_DIR/state/quickshell-widgets"
export QS_CACHE_DIR="$TMP_DIR/cache/quickshell-widgets" MPRIS_MKDIR_LOG="$TMP_DIR/mkdir-calls"
printf '{}\n' > "$QS_CONFIG_DIR/settings.json"
printf '{}\n' > "$QS_DATA_DIR/calendar-notes.json"
cat > "$TMP_DIR/bin/mkdir" <<'STUB'
#!/usr/bin/env bash
printf 'mkdir\n' >> "$MPRIS_MKDIR_LOG"
exec /bin/mkdir "$@"
STUB
chmod +x "$TMP_DIR/bin/mkdir"
export PATH="$TMP_DIR/bin:$PATH"
source "$ROOT/scripts/player.d/common.sh"
url='https://cdn.example/benchmark/cover.jpg?version=1'
digest="$(printf '%s' "$url" | sha256sum)"
key="${digest%% *}"; key="${key:0:32}"
image_path="$IMG_PATH/mpris-art-${key}.png"
printf 'MOCK_PNG\n' > "$image_path"

measure() {
    local mode="$1" start end i
    : > "$MPRIS_MKDIR_LOG"
    start="${EPOCHREALTIME/./}"
    for ((i=0; i<ITERATIONS; i++)); do
        if [[ "$mode" == before ]]; then
            # The previous get_image path called mkdir -p before checking cache.
            mkdir -p "$IMG_PATH" 2>/dev/null
        fi
        get_image "$url" >/dev/null
    done
    end="${EPOCHREALTIME/./}"
    printf '%s %s\n' "$((end - start))" "$(wc -l < "$MPRIS_MKDIR_LOG")"
}

before=() after=() before_calls=0 after_calls=0
for ((trial=1; trial<=TRIALS; trial++)); do
    read -r time calls < <(measure before); before+=("$time"); before_calls="$calls"
    read -r time calls < <(measure after); after+=("$time"); after_calls="$calls"
done
mid="$(((TRIALS + 1) / 2))"
before_us="$(printf '%s\n' "${before[@]}" | sort -n | sed -n "${mid}p")"
after_us="$(printf '%s\n' "${after[@]}" | sort -n | sed -n "${mid}p")"
printf 'iterations per trial: %s; trials: %s\n' "$ITERATIONS" "$TRIALS"
printf 'before: median %d.%03d ms; mkdir calls %d per trial\n' "$((before_us / 1000))" "$((before_us % 1000))" "$before_calls"
printf 'after:  median %d.%03d ms; mkdir calls %d per trial\n' "$((after_us / 1000))" "$((after_us % 1000))" "$after_calls"
