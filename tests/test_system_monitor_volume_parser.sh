#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/system_monitor.d/volumes.sh"
fail() { echo "System monitor volume parser: FAIL: $*" >&2; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
REAL_JQ="$(command -v jq)"
JQ_CALL_COUNT="$TMP/jq-calls"
export REAL_JQ JQ_CALL_COUNT
cat > "$TMP/jq" <<'MOCK_JQ'
#!/usr/bin/env bash
set -euo pipefail
printf 'call\n' >> "$JQ_CALL_COUNT"
exec "$REAL_JQ" "$@"
MOCK_JQ
chmod +x "$TMP/jq"
cat > "$TMP/pactl" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
[[ "${1:-}" == "list" && "${2:-}" == "sink-inputs" ]] || exit 2
cat "$PACTL_FIXTURE"
MOCK
chmod +x "$TMP/pactl"
export PATH="$TMP:$PATH"

cat > "$TMP/pactl-english.txt" <<'EOF_EN'
Sink Input #42
    Driver: protocol-native.c
    Properties:
        media.name = "Browser \"Music\" \\ Stream"
    Volume: front-left: 65536 / 100% / 0.00 dB, front-right: 65536 / 100% / 0.00 dB
    Muted: no
Sink Input #87
    Properties:
        media.name = "Video Player"
    Volume: front-left: 32768 / 50% / -18.06 dB, front-right: 32768 / 50% / -18.06 dB
EOF_EN
PACTL_FIXTURE="$TMP/pactl-english.txt"; export PACTL_FIXTURE
: > "$JQ_CALL_COUNT"
english="$(get_volumes)"
[[ ! -s "$JQ_CALL_COUNT" ]] || fail "volume collector should not launch jq for JSON encoding"
printf '%s\n' "$english" | "$REAL_JQ" -e '
  length == 2 and
  .[0].num == "42" and .[0].value == "100" and .[0].name == "Browser \"Music\" \\ Stream" and
  .[1].num == "87" and .[1].value == "50" and .[1].name == "Video Player"
' >/dev/null || fail "English pactl output or JSON escaping is incorrect: $english"

cat > "$TMP/pactl-russian.txt" <<'EOF_RU'
Вход аудиоприёмника №13
    Свойства:
        media.name = "Браузер и музыка"
    Громкость: фронт-левый: 65536 / 75% / 0.00 дБ, фронт-правый: 65536 / 75% / 0.00 дБ
    Заглушен: нет
Вход аудиоприёмника №29
    Свойства:
        media.name = "Плеер"
    Громкость: фронт-левый: 32768 / 22% / -18.06 дБ, фронт-правый: 32768 / 22% / -18.06 дБ
EOF_RU
PACTL_FIXTURE="$TMP/pactl-russian.txt"; export PACTL_FIXTURE
: > "$JQ_CALL_COUNT"
russian="$(get_volumes)"
[[ ! -s "$JQ_CALL_COUNT" ]] || fail "Russian volume collector should not launch jq for JSON encoding"
printf '%s\n' "$russian" | "$REAL_JQ" -e '
  length == 2 and
  .[0].num == "13" and .[0].value == "75" and .[0].name == "Браузер и музыка" and
  .[1].num == "29" and .[1].value == "22" and .[1].name == "Плеер"
' >/dev/null || fail "Russian pactl output is incorrect: $russian"

: > "$TMP/pactl-empty.txt"
PACTL_FIXTURE="$TMP/pactl-empty.txt"; export PACTL_FIXTURE
: > "$JQ_CALL_COUNT"
empty="$(get_volumes)"
[[ "$empty" == '[]' ]] || fail "empty sink-input output should return [], got: $empty"
[[ ! -s "$JQ_CALL_COUNT" ]] || fail "empty sink-input output should not start jq"

# The built-in encoder must preserve difficult names without a jq subprocess.
raw_name=$'Control\001\002\037\177 backspace\b formfeed\f newline\n tab\t CR\r quote " slash \\ — 東京 🎵'
escaped_name=""
system_monitor_volume_json_escape_into escaped_name "$raw_name"
printf '"%s"\n' "$escaped_name" | "$REAL_JQ" -e --arg expected "$raw_name" '. == $expected' >/dev/null || fail "built-in JSON escaping changed a difficult string"
[[ ! -s "$JQ_CALL_COUNT" ]] || fail "volume JSON escaping unexpectedly launched jq"
if system_monitor_volume_encode_fields 42 100 >/dev/null 2>&1; then
    fail "volume encoder accepted an incomplete num/value/name record"
fi

echo "System monitor volume parser locale and built-in JSON escaping: OK"
