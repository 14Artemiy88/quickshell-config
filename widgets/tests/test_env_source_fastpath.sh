#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
REAL_MKDIR="$(command -v mkdir)"
REAL_DIRNAME="$(command -v dirname)"
mkdir -p "$TMP_DIR/bin"
cat > "$TMP_DIR/bin/mkdir" <<'STUB'
#!/usr/bin/env bash
printf 'mkdir\n' >> "$CALL_LOG"
exec "$REAL_MKDIR" "$@"
STUB
cat > "$TMP_DIR/bin/dirname" <<'STUB'
#!/usr/bin/env bash
printf 'dirname\n' >> "$CALL_LOG"
exec "$REAL_DIRNAME" "$@"
STUB
chmod +x "$TMP_DIR/bin/mkdir" "$TMP_DIR/bin/dirname"
export REAL_MKDIR REAL_DIRNAME CALL_LOG="$TMP_DIR/calls" PATH="$TMP_DIR/bin:$PATH"
export HOME="$TMP_DIR/home" XDG_RUNTIME_DIR="$TMP_DIR/runtime"
export QS_PROJECT_DIR="$ROOT" QS_CONFIG_DIR="$TMP_DIR/config" QS_DATA_DIR="$TMP_DIR/data" QS_STATE_DIR="$TMP_DIR/state" QS_CACHE_DIR="$TMP_DIR/cache"

# First source: directories are missing, so exactly one mkdir is expected.
bash -c 'source "$QS_PROJECT_DIR/scripts/env"' 
[[ -d "$QS_CONFIG_DIR" && -d "$QS_DATA_DIR" && -d "$QS_STATE_DIR" && -d "$QS_CACHE_DIR" ]] || {
    echo "env did not create all missing XDG directories" >&2; exit 1;
}
mkdir_count="$(grep -c '^mkdir$' "$CALL_LOG" || true)"
dirname_count="$(grep -c '^dirname$' "$CALL_LOG" || true)"
[[ "$mkdir_count" == 1 ]] || { echo "first env source should use one mkdir, got $mkdir_count" >&2; exit 1; }
[[ "$dirname_count" == 0 ]] || { echo "env migration markers still call dirname ($dirname_count)" >&2; exit 1; }

# Create migration marker files so repeated sources exercise the stable path.
: > "$QS_CONFIG_DIR/.migration-settings-v1"
: > "$QS_DATA_DIR/.migration-calendar-notes-v1"
: > "$CALL_LOG"
for _ in {1..10}; do bash -c 'source "$QS_PROJECT_DIR/scripts/env"'; done
mkdir_count="$(grep -c '^mkdir$' "$CALL_LOG" || true)"
dirname_count="$(grep -c '^dirname$' "$CALL_LOG" || true)"
[[ "$mkdir_count" == 0 ]] || { echo "warm env source still calls mkdir ($mkdir_count)" >&2; exit 1; }
[[ "$dirname_count" == 0 ]] || { echo "warm env source still calls dirname ($dirname_count)" >&2; exit 1; }
printf 'env creates missing XDG directories once; warm sources invoke no mkdir or dirname: OK\n'
