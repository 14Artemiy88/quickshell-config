#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { printf 'Player script directory fast path: FAIL: %s\n' "$1" >&2; exit 1; }

for file in "$ROOT/scripts/player" "$ROOT/scripts/player.d/common.sh"; do
    grep -Eq 'PLAYER_(SCRIPT|LIB)_PATH="\$\{BASH_SOURCE\[0\]\}"' "$file" || \
        fail "missing Bash source-path handling in $file"
    if grep -Eq 'dirname[[:space:]]+.*BASH_SOURCE' "$file"; then
        fail "external dirname remains in $file"
    fi
done

REAL_JQ="$(command -v jq)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
project="$work/Player Project With Spaces"
mkdir -p "$project/scripts/player.d" "$project/scripts/mopidy" "$work/bin"
cp "$ROOT/scripts/player" "$project/scripts/player"
cp "$ROOT/scripts/player.d/common.sh" "$project/scripts/player.d/common.sh"
cat > "$project/scripts/env" <<'ENV'
#!/usr/bin/env bash
QS_PROJECT_DIR="${QS_PROJECT_DIR:-/test/project}"
export QS_PROJECT_DIR
ENV
cat > "$project/scripts/mopidy/player_backend.sh" <<'STUB'
#!/usr/bin/env bash
get_mopidy_player_metadata() { :; }
STUB
for backend in backend_mpv.sh backend_mpris.sh backend_deadbeef.sh; do
    case "$backend" in
        backend_mpv.sh) fn=get_mpv_player_metadata ;;
        backend_mpris.sh) fn=get_mpris_player_metadata ;;
        backend_deadbeef.sh) fn=get_deadbeef_player_metadata ;;
    esac
    printf '#!/usr/bin/env bash\n%s() { :; }\n' "$fn" > "$project/scripts/player.d/$backend"
done
cat > "$work/bin/jq" <<'JQ'
#!/usr/bin/env bash
printf 'jq\n' >> "$TEST_JQ_LOG"
printf '{}\n'
JQ
cat > "$work/bin/dirname" <<'DIRNAME'
#!/usr/bin/env bash
printf 'dirname\n' >> "$TEST_DIRNAME_LOG"
exit 99
DIRNAME
chmod +x "$work/bin/jq" "$work/bin/dirname"
export PATH="$work/bin:$PATH" TEST_DIRNAME_LOG="$work/dirname.log" TEST_JQ_LOG="$work/jq.log" QS_CONFIG_DIR="$work/config" QS_DATA_DIR="$work/data" QS_STATE_DIR="$work/state" QS_CACHE_DIR="$work/cache"
: > "$TEST_DIRNAME_LOG"
: > "$TEST_JQ_LOG"

absolute_output="$(QS_PROJECT_DIR="$project" bash "$project/scripts/player" --priority no_backend)"
"$REAL_JQ" -e --arg image "$project/assets/1px.png" ' .text == "silence" and .image == $image and .title_class == "default" ' <<< "$absolute_output" >/dev/null || fail "absolute path with spaces failed: $absolute_output"
[[ ! -s "$TEST_DIRNAME_LOG" ]] || fail "absolute invocation launched dirname"

relative_output="$(cd "$project" && QS_PROJECT_DIR="$project" bash scripts/player --priority no_backend)"
"$REAL_JQ" -e --arg image "$project/assets/1px.png" ' .text == "silence" and .image == $image and .title_class == "default" ' <<< "$relative_output" >/dev/null || fail "relative path with spaces failed: $relative_output"
[[ ! -s "$TEST_DIRNAME_LOG" ]] || fail "relative invocation launched dirname"
[[ ! -s "$TEST_JQ_LOG" ]] || fail "Player JSON serialization launched jq"

echo 'Player script directory fast path and absolute/relative paths with spaces: OK'
