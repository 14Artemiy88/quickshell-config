#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export XDG_RUNTIME_DIR="$TMP/runtime"
export XDG_CONFIG_HOME="$TMP/config"
export XDG_DATA_HOME="$TMP/data"
export XDG_STATE_HOME="$TMP/state"
export XDG_CACHE_HOME="$TMP/cache"
mkdir -p "$XDG_RUNTIME_DIR" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"
source "$ROOT/scripts/player.d/common.sh"

source_path='/media/Some video with spaces.mkv'
stdout_key="$(mpv_snapshot_key "$source_path")"
mpv_snapshot_key_into "$source_path" direct_key || { echo 'direct source-key assignment failed' >&2; exit 1; }
[[ "$direct_key" == "$stdout_key" && "$direct_key" =~ ^[0-9a-f]{24}$ ]] || {
    echo 'direct and stdout source-key helpers differ' >&2; exit 1;
}

snapshot_name="mpv-${direct_key}-1760102030123456789.png"
snapshot_path="$IMG_PATH/$snapshot_name"
mkdir -p "$IMG_PATH"
printf 'test image payload\n' > "$snapshot_path"
mpv_store_latest_snapshot_for_key "$direct_key" "$snapshot_name"

stdout_path="$(mpv_latest_snapshot_for_key "$direct_key")"
mpv_latest_snapshot_for_key_into "$direct_key" direct_path || {
    echo 'direct snapshot-path assignment failed' >&2; exit 1;
}
[[ "$stdout_path" == "$snapshot_path" && "$direct_path" == "$stdout_path" ]] || {
    echo 'direct and stdout snapshot-path helpers differ' >&2; exit 1;
}

# A recorded miss clears the caller-provided result and keeps the old stdout API.
mpv_store_latest_snapshot_for_key "$direct_key" ""
direct_path='stale-value'
if mpv_latest_snapshot_for_key_into "$direct_key" direct_path; then
    echo 'negative snapshot sidecar unexpectedly returned a path' >&2; exit 1
fi
[[ -z "$direct_path" ]] || { echo 'miss did not clear caller variable' >&2; exit 1; }
if mpv_latest_snapshot_for_key "$direct_key" >/dev/null; then
    echo 'stdout compatibility wrapper reported a cache hit for a miss' >&2; exit 1
fi

# The polled hot path must assign keys and snapshot lookup results directly.
if grep -Fq 'key=$(mpv_snapshot_key "$source_path")' "$ROOT/scripts/player.d/common.sh"; then
    echo 'command-substitution source-key lookup remains' >&2; exit 1
fi
if grep -Fq 'latest=$(mpv_latest_snapshot_for_key "$key")' "$ROOT/scripts/player.d/common.sh"; then
    echo 'command-substitution snapshot lookup remains' >&2; exit 1
fi
grep -Fq 'mpv_snapshot_key_into "$source_path" key || return 1' "$ROOT/scripts/player.d/common.sh" || {
    echo 'direct key assignment path missing' >&2; exit 1;
}
grep -Fq 'mpv_latest_snapshot_for_key_into "$key" cached_latest || cached_latest=""' "$ROOT/scripts/player.d/common.sh" || {
    echo 'direct snapshot lookup path missing' >&2; exit 1;
}

echo 'mpv snapshot lookup direct assignment and stdout compatibility: OK'
