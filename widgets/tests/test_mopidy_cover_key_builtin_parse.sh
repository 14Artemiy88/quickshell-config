#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
mkdir -p "$TMP_DIR/bin" "$TMP_DIR/cache" "$TMP_DIR/runtime" "$TMP_DIR/config" "$TMP_DIR/data" "$TMP_DIR/state"
export HOME="$TMP_DIR/home" XDG_CACHE_HOME="$TMP_DIR/cache" XDG_RUNTIME_DIR="$TMP_DIR/runtime"
export XDG_CONFIG_HOME="$TMP_DIR/config" XDG_DATA_HOME="$TMP_DIR/data" XDG_STATE_HOME="$TMP_DIR/state"
REAL_PYTHON="$(command -v python3)"
export REAL_PYTHON QS_PROJECT_DIR="$ROOT" AWK_CALL_LOG="$TMP_DIR/awk-calls" PYTHON_CALL_LOG="$TMP_DIR/python-calls"
mkdir -p "$HOME" "$XDG_CACHE_HOME/quickshell-widgets/mopidy-covers"

cat > "$TMP_DIR/bin/awk" <<'STUB'
#!/usr/bin/env bash
printf 'awk\n' >> "$AWK_CALL_LOG"
exit 97
STUB
cat > "$TMP_DIR/bin/file" <<'STUB'
#!/usr/bin/env bash
printf 'image/png\n'
STUB
cat > "$TMP_DIR/bin/python3" <<'STUB'
#!/usr/bin/env bash
printf 'python3\n' >> "$PYTHON_CALL_LOG"
exec "$REAL_PYTHON" "$@"
STUB
chmod +x "$TMP_DIR/bin/awk" "$TMP_DIR/bin/file" "$TMP_DIR/bin/python3"
export PATH="$TMP_DIR/bin:$PATH"

track_uri='http://music.test/track id?source=library'
cover="$TMP_DIR/cover.png"
printf 'mock cover bytes\n' > "$cover"
# Seed the existing cache entry using the unchanged digest input format.
hash_output="$(printf '%s' "$track_uri" | sha256sum)"
key="${hash_output%% *}"
printf 'file://%s\n' "$cover" > "$XDG_CACHE_HOME/quickshell-widgets/mopidy-covers/$key.uri"

result="$(bash -c '
  set -euo pipefail
  source "$QS_PROJECT_DIR/scripts/player.d/common.sh"
  source "$QS_PROJECT_DIR/scripts/mopidy/player_backend.sh"
  mopidy_cover_for_track "$1"
' _ "$track_uri")"
[[ "$result" == "$cover" ]] || { echo "Mopidy cover key parse: unexpected result: $result" >&2; exit 1; }
[[ ! -s "$AWK_CALL_LOG" ]] || { echo "Mopidy cover cache key still launched awk" >&2; exit 1; }
[[ ! -s "$PYTHON_CALL_LOG" ]] || { echo "Non-local Mopidy URI still launched Python" >&2; exit 1; }

# Local file URIs still use Python's URL decoder so percent escapes survive.
local_path="$(bash -c '
  set -euo pipefail
  source "$QS_PROJECT_DIR/scripts/mopidy/player_backend.sh"
  mopidy_local_track_path "file:///tmp/Artist%20Name/track.flac"
')"
[[ "$local_path" == '/tmp/Artist Name/track.flac' ]] || { echo "Local file URI decoding changed: $local_path" >&2; exit 1; }
[[ -s "$PYTHON_CALL_LOG" ]] || { echo "Local URI did not use the URL decoder" >&2; exit 1; }
printf 'Mopidy cached cover key uses Bash; non-local URI skips Python; local file URI decoding remains intact: OK\n'
