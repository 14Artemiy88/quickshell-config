#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
mkdir -p "$TMP_DIR/bin" "$TMP_DIR/home" "$TMP_DIR/cache" "$TMP_DIR/runtime" "$TMP_DIR/config" "$TMP_DIR/data" "$TMP_DIR/state"
export HOME="$TMP_DIR/home"
export XDG_CACHE_HOME="$TMP_DIR/cache" XDG_RUNTIME_DIR="$TMP_DIR/runtime"
export XDG_CONFIG_HOME="$TMP_DIR/config" XDG_DATA_HOME="$TMP_DIR/data" XDG_STATE_HOME="$TMP_DIR/state"
export QS_PROJECT_DIR="$ROOT" MOPIDY_MKDIR_LOG="$TMP_DIR/mkdir.log"
REAL_MKDIR="$(command -v mkdir)"
export REAL_MKDIR
cat > "$TMP_DIR/bin/mkdir" <<'STUB'
#!/usr/bin/env bash
printf 'mkdir\n' >> "$MOPIDY_MKDIR_LOG"
exec "$REAL_MKDIR" "$@"
STUB
chmod +x "$TMP_DIR/bin/mkdir"
export PATH="$TMP_DIR/bin:$PATH"

bash -c '
  set -euo pipefail
  source "$QS_PROJECT_DIR/scripts/player.d/common.sh"
  source "$QS_PROJECT_DIR/scripts/mopidy/player_backend.sh"
  mopidy_rpc() { printf "{\"result\":{}}\\n"; }
  track_uri="http://music.test/track-no-cover-cache-dir"
  cache_dir="$QS_CACHE_DIR/mopidy-covers"
  rm -rf "$cache_dir"
  : > "$MOPIDY_MKDIR_LOG"

  # Cold cache: guarded mkdir must create the directory exactly once.
  result=$(mopidy_cover_for_track "$track_uri")
  [[ -d "$cache_dir" ]] || { echo "cold lookup did not create the cover cache" >&2; exit 1; }
  [[ "$(wc -l < "$MOPIDY_MKDIR_LOG")" -eq 1 ]] || { echo "cold lookup should invoke mkdir once" >&2; exit 1; }

  # Warm negative-cache hits should not invoke mkdir. Metadata is cached and
  # the 30-second negative-cache window prevents a new RPC call.
  for _ in {1..5}; do
    result=$(mopidy_cover_for_track "$track_uri")
    [[ "$result" == "$DEFAULT_IMG" ]] || { echo "unexpected cover fallback on warm hit" >&2; exit 1; }
  done
  [[ "$(wc -l < "$MOPIDY_MKDIR_LOG")" -eq 1 ]] || { echo "mkdir launched despite existing cover cache directory" >&2; exit 1; }
'
printf 'Mopidy cover cache directory is created on cold path only: OK\n'
