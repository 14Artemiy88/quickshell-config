#!/usr/bin/env bash
# Isolate the repeated image-validation branch used by cached Mopidy cover polls.
# The before path models the old two validations; after validates the same file once.
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
ITERATIONS="${1:-200}"
TRIALS="${2:-5}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
mkdir -p "$TMP_DIR/bin" "$TMP_DIR/home" "$TMP_DIR/cache" "$TMP_DIR/runtime" "$TMP_DIR/config" "$TMP_DIR/data" "$TMP_DIR/state"
export HOME="$TMP_DIR/home" XDG_CACHE_HOME="$TMP_DIR/cache" XDG_RUNTIME_DIR="$TMP_DIR/runtime"
export XDG_CONFIG_HOME="$TMP_DIR/config" XDG_DATA_HOME="$TMP_DIR/data" XDG_STATE_HOME="$TMP_DIR/state"
export QS_PROJECT_DIR="$ROOT" MOPIDY_FILE_CALL_LOG="$TMP_DIR/file-calls"
cat > "$TMP_DIR/bin/file" <<'STUB'
#!/usr/bin/env bash
printf 'file\n' >> "$MOPIDY_FILE_CALL_LOG"
for target in "$@"; do :; done
[[ -s "$target" ]] && printf 'image/png\n' || printf 'text/plain\n'
STUB
chmod +x "$TMP_DIR/bin/file"
export PATH="$TMP_DIR/bin:$PATH"
source "$ROOT/scripts/player.d/common.sh"
source "$ROOT/scripts/mopidy/player_backend.sh"
CACHED_IMAGE="$TMP_DIR/cached-cover.png"
printf 'MOCK_IMAGE:benchmark\n' > "$CACHED_IMAGE"

measure() {
    local mode="$1" start end i
    : > "$MOPIDY_FILE_CALL_LOG"
    start="${EPOCHREALTIME/./}"
    for ((i=0; i<ITERATIONS; i++)); do
        if [[ "$mode" == before ]]; then
            # The old cache-hit path validated once to reject a corrupt file,
            # then redundantly validated the exact same file after the branch.
            if [[ -e "$CACHED_IMAGE" ]] && ! mopidy_is_image_file "$CACHED_IMAGE"; then :; fi
            mopidy_is_image_file "$CACHED_IMAGE" >/dev/null
        else
            mopidy_is_image_file "$CACHED_IMAGE" >/dev/null
        fi
    done
    end="${EPOCHREALTIME/./}"
    printf '%s %s\n' "$((end - start))" "$(wc -l < "$MOPIDY_FILE_CALL_LOG")"
}

before=() after=()
before_calls=0
after_calls=0
for ((trial=1; trial<=TRIALS; trial++)); do
    read -r time calls < <(measure before)
    before+=("$time")
    before_calls="$calls"
    read -r time calls < <(measure after)
    after+=("$time")
    after_calls="$calls"
done
mid="$(((TRIALS + 1) / 2))"
before_us="$(printf '%s\n' "${before[@]}" | sort -n | sed -n "${mid}p")"
after_us="$(printf '%s\n' "${after[@]}" | sort -n | sed -n "${mid}p")"
printf 'iterations per trial: %s; trials: %s\n' "$ITERATIONS" "$TRIALS"
printf 'before: median %d.%03d ms; file calls %d per trial\n' "$((before_us / 1000))" "$((before_us % 1000))" "$before_calls"
printf 'after:  median %d.%03d ms; file calls %d per trial\n' "$((after_us / 1000))" "$((after_us % 1000))" "$after_calls"
