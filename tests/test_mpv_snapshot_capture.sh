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
export FFMPEG_LOG="$TMP_DIR/ffmpeg.log"
export FFMPEG_FAIL=0
export SNAPSHOT_SCAN_LOG="$TMP_DIR/snapshot-scan.log"
: > "$SNAPSHOT_SCAN_LOG"
export PATH="$TMP_DIR/bin:$PATH"

# These wrappers only log discovery-pipeline utilities when SNAPSHOT_SCAN_LOG
# is set for a specific call. They let the test prove that a normal cache hit
# no longer launches find/sort/head without perturbing unrelated assertions.
for tool in find sort head; do
    cat > "$TMP_DIR/bin/$tool" <<STUB
#!/bin/bash
if [[ -n "\${SNAPSHOT_SCAN_TRACE:-}" && -n "\${SNAPSHOT_SCAN_LOG:-}" ]]; then
    printf '%s\n' '$tool' >> "\$SNAPSHOT_SCAN_LOG"
fi
exec /usr/bin/$tool "\$@"
STUB
    chmod +x "$TMP_DIR/bin/$tool"
done

cat > "$TMP_DIR/bin/ffmpeg" <<'STUB'
#!/bin/bash
printf '%s\n' "$*" >> "$FFMPEG_LOG"
[[ "${FFMPEG_FAIL:-0}" == "1" ]] && exit 1
output=""
for arg in "$@"; do output="$arg"; done
[[ -n "$output" ]] || exit 2
printf 'fake-png-frame-%s\n' "${CAPTURE_MARKER:-frame}" > "$output"
STUB
chmod +x "$TMP_DIR/bin/ffmpeg"

source "$ROOT/scripts/player.d/common.sh"

source_path='/media/Example video #1 [test].mkv'
first="$(get_mpv_snapshot "$source_path" '12.5' false 60)"
[[ -s "$first" ]] || { echo "first capture missing" >&2; exit 1; }
[[ "${first##*/}" =~ ^mpv-[a-f0-9]{24}-[0-9]+\.png$ ]] || {
    echo "snapshot filename is not source-keyed/versioned: $first" >&2; exit 1;
}
[[ "$(wc -l < "$FFMPEG_LOG")" -eq 1 ]] || { echo "expected one ffmpeg invocation" >&2; exit 1; }
grep -F -- '-ss 12.5' "$FFMPEG_LOG" >/dev/null || { echo "position was not passed to ffmpeg" >&2; exit 1; }

# The periodic backend reuses a fresh snapshot until the 60-second TTL expires.
scan_before="$(wc -l < "$SNAPSHOT_SCAN_LOG")"
second="$(SNAPSHOT_SCAN_TRACE=1 SNAPSHOT_SCAN_LOG="$SNAPSHOT_SCAN_LOG" get_mpv_snapshot "$source_path" '13.5' false 60)"
[[ "$second" == "$first" ]] || { echo "fresh snapshot was not reused" >&2; exit 1; }
[[ "$(wc -l < "$FFMPEG_LOG")" -eq 1 ]] || { echo "fresh cache unexpectedly recaptured" >&2; exit 1; }
[[ "$(wc -l < "$SNAPSHOT_SCAN_LOG")" -eq "$scan_before" ]] || {
    echo "fresh snapshot cache hit launched find/sort/head instead of using the sidecar" >&2; exit 1;
}

# The first access to a legacy snapshot without the sidecar performs one
# discovery scan, then atomically creates the index for subsequent polls.
key="$(mpv_snapshot_key "$source_path")"
rm -f -- "$IMG_PATH/.mpv-${key}.latest"
scan_before="$(wc -l < "$SNAPSHOT_SCAN_LOG")"
migrated="$(SNAPSHOT_SCAN_TRACE=1 SNAPSHOT_SCAN_LOG="$SNAPSHOT_SCAN_LOG" get_mpv_snapshot "$source_path" '14' false 60)"
[[ "$migrated" == "$first" ]] || { echo "legacy snapshot migration changed the current frame" >&2; exit 1; }
[[ -s "$IMG_PATH/.mpv-${key}.latest" ]] || { echo "legacy snapshot sidecar was not recreated" >&2; exit 1; }
scan_calls="$(tail -n +$((scan_before + 1)) "$SNAPSHOT_SCAN_LOG")"
for tool in find sort head; do
    grep -Fx "$tool" <<< "$scan_calls" >/dev/null || { echo "legacy migration did not use expected $tool scan" >&2; exit 1; }
done
scan_before="$(wc -l < "$SNAPSHOT_SCAN_LOG")"
again="$(SNAPSHOT_SCAN_TRACE=1 SNAPSHOT_SCAN_LOG="$SNAPSHOT_SCAN_LOG" get_mpv_snapshot "$source_path" '14.5' false 60)"
[[ "$again" == "$first" && "$(wc -l < "$SNAPSHOT_SCAN_LOG")" -eq "$scan_before" ]] || {
    echo "snapshot sidecar did not avoid follow-up discovery scans" >&2; exit 1;
}

# An expired image triggers the periodic one-minute refresh.
touch -d '2 minutes ago' "$first"
export CAPTURE_MARKER=periodic
third="$(get_mpv_snapshot "$source_path" '15' false 60)"
[[ -s "$third" && "$third" != "$first" ]] || { echo "expired snapshot was not refreshed" >&2; exit 1; }
[[ "$(wc -l < "$FFMPEG_LOG")" -eq 2 ]] || { echo "expired snapshot did not invoke ffmpeg" >&2; exit 1; }
grep -F -- '-ss 15' "$FFMPEG_LOG" >/dev/null || { echo "refresh position was not passed to ffmpeg" >&2; exit 1; }

# Pause/seek forces a new filename so QtQuick.Image sees an updated URL.
export CAPTURE_MARKER=forced
fourth="$(get_mpv_snapshot "$source_path" '20' true 0)"
[[ -s "$fourth" && "$fourth" != "$third" ]] || { echo "forced capture did not create a new snapshot" >&2; exit 1; }
[[ "$(wc -l < "$FFMPEG_LOG")" -eq 3 ]] || { echo "forced capture did not invoke ffmpeg" >&2; exit 1; }
grep -F -- '-ss 20' "$FFMPEG_LOG" >/dev/null || { echo "forced position was not passed to ffmpeg" >&2; exit 1; }

# Failed ffmpeg captures must keep the last known-good image and clean temp files.
export FFMPEG_FAIL=1
fallback="$(get_mpv_snapshot "$source_path" '30' true 0)"
[[ "$fallback" == "$fourth" && -s "$fallback" ]] || { echo "capture failure did not retain last valid snapshot" >&2; exit 1; }
if find "$IMG_PATH" -maxdepth 1 -name '*.tmp.png' -print -quit | grep -q .; then
    echo "temporary snapshot was left behind" >&2
    exit 1
fi

# Repeated failures on an unsupported source are throttled to one attempt per TTL.
export FFMPEG_FAIL=1
bad_source='/media/Unsupported stream.webm'
bad_first="$(SNAPSHOT_SCAN_TRACE=1 SNAPSHOT_SCAN_LOG="$SNAPSHOT_SCAN_LOG" get_mpv_snapshot "$bad_source" '1' false 60)" || bad_first=""
[[ -z "$bad_first" ]] || { echo "failed source unexpectedly returned a snapshot" >&2; exit 1; }
failed_count="$(wc -l < "$FFMPEG_LOG")"
scan_before="$(wc -l < "$SNAPSHOT_SCAN_LOG")"
bad_second="$(SNAPSHOT_SCAN_TRACE=1 SNAPSHOT_SCAN_LOG="$SNAPSHOT_SCAN_LOG" get_mpv_snapshot "$bad_source" '2' false 60)" || bad_second=""
[[ -z "$bad_second" && "$(wc -l < "$FFMPEG_LOG")" -eq "$failed_count" ]] || {
    echo "failed source was retried before the refresh interval" >&2; exit 1;
}
[[ "$(wc -l < "$SNAPSHOT_SCAN_LOG")" -eq "$scan_before" ]] || {
    echo "failed source repeated snapshot discovery before retry TTL" >&2; exit 1;
}

# A new source must use its own cache key, not reuse the previous video's frame.
export FFMPEG_FAIL=0
other="$(get_mpv_snapshot '/media/Other video.mkv' '2' false 60)"
[[ -s "$other" && "$other" != "$fourth" ]] || { echo "different source reused the wrong snapshot" >&2; exit 1; }

printf 'mpv snapshot capture: OK\n'
