#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf -- "$TMP_DIR"' EXIT
REAL_JQ="$(command -v jq)"
mkdir -p "$TMP_DIR/bin"
export REAL_JQ JQ_CALL_LOG="$TMP_DIR/jq-calls"
export PATH="$TMP_DIR/bin:$PATH"

cat > "$TMP_DIR/bin/jq" <<'STUB'
#!/usr/bin/env bash
printf 'jq\n' >> "$JQ_CALL_LOG"
exec "$REAL_JQ" "$@"
STUB
chmod +x "$TMP_DIR/bin/jq"

# Keep tricky characters raw until the shared serializer. Include control bytes,
# quotes, backslashes, multiline text, and non-ASCII characters in several fields.
export TEST_PLAYER_TITLE=$'A "quoted" title \\ path\nsecond\tcolumn\001 — 東京 🎵'
export TEST_PLAYER_ARTIST=$'Artist\r\nName \\ "quoted"'
export TEST_PLAYER_IMAGE='/tmp/cover\\folder"name.png'
: > "$JQ_CALL_LOG"
output="$(bash -c '
    source "$1"
    get_json \
      --first_line "$TEST_PLAYER_TITLE" \
      --second_line "$TEST_PLAYER_ARTIST" \
      --third_line $'"'"'third\nline'"'"' \
      --timeleft $'"'"'-00:42\tremaining'"'"' \
      --pos_ms 1250 --dur_ms 5000 --status $'"'"'P\\lay\\"ing'"'"' \
      --image "$TEST_PLAYER_IMAGE" --artist "$TEST_PLAYER_ARTIST" \
      --player spotify --title_class custom
' _ "$ROOT/scripts/player.d/common.sh")"

[[ ! -s "$JQ_CALL_LOG" ]] || { echo 'get_json launched jq during serialization' >&2; cat "$JQ_CALL_LOG" >&2; exit 1; }
"$REAL_JQ" -e \
    --arg first "$TEST_PLAYER_TITLE" \
    --arg second "$TEST_PLAYER_ARTIST" \
    --arg image "$TEST_PLAYER_IMAGE" \
    '.first_line == $first and .second_line == $second and .third_line == "third\nline" and
     .timeleft == "-00:42\tremaining" and .position == "25" and .duration == "5000" and
     .status == "P\\lay\\\"ing" and .image == $image and .text == $second and
     .player == "spotify" and .title_class == "custom" and
     ([.[] | type] | all(. == "string"))' <<< "$output" >/dev/null || {
       printf 'Player JSON serializer changed values or field types: %s\n' "$output" >&2
       exit 1
    }

# Check empty/default fields and clamp behavior via the non-exiting builder API.
bash -c '
  source "$1"
  player_build_json_into payload "" "" "" "" 100 "" "" "" "" default ""
  printf "%s\\n" "$payload"
' _ "$ROOT/scripts/player.d/common.sh" | "$REAL_JQ" -e '
    .first_line == "" and .second_line == "" and .third_line == "" and
    .position == "100" and .title_class == "default" and .duration == ""
  ' >/dev/null

printf 'Player JSON serialization without per-poll jq: OK\n'
