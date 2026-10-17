#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
mkdir -p "$TMP_DIR/bin" "$TMP_DIR/runtime" "$TMP_DIR/config" "$TMP_DIR/data" "$TMP_DIR/state" "$TMP_DIR/cache" "$TMP_DIR/home"
REAL_JQ="$(command -v jq)"
REAL_AWK="$(command -v awk)"
REAL_DATE="$(command -v date)"
export REAL_JQ REAL_AWK REAL_DATE
export JQ_CALL_LOG="$TMP_DIR/jq-calls"
export AWK_CALL_LOG="$TMP_DIR/awk-calls"
export DATE_CALL_LOG="$TMP_DIR/date-calls"
: > "$JQ_CALL_LOG"
: > "$AWK_CALL_LOG"
: > "$DATE_CALL_LOG"
export MPV_RUNNING=1
export XDG_RUNTIME_DIR="$TMP_DIR/runtime"
export XDG_CONFIG_HOME="$TMP_DIR/config"
export XDG_DATA_HOME="$TMP_DIR/data"
export XDG_STATE_HOME="$TMP_DIR/state"
export XDG_CACHE_HOME="$TMP_DIR/cache"
export HOME="$TMP_DIR/home"
export PATH="$TMP_DIR/bin:$PATH"
fail() { echo "mpv metadata batched parse: FAIL: $*" >&2; exit 1; }

cat > "$TMP_DIR/bin/pgrep" <<'STUB'
#!/usr/bin/env bash
[[ "${1:-}" == "-x" && "${2:-}" == "mpv" && "${MPV_RUNNING:-0}" == "1" ]]
STUB
cat > "$TMP_DIR/bin/socat" <<'STUB'
#!/usr/bin/env bash
printf '%s' "${MPV_RESPONSE:-}"
STUB
cat > "$TMP_DIR/bin/jq" <<'STUB'
#!/usr/bin/env bash
printf 'jq\n' >> "$JQ_CALL_LOG"
exec "$REAL_JQ" "$@"
STUB
cat > "$TMP_DIR/bin/awk" <<'STUB'
#!/usr/bin/env bash
printf 'awk\n' >> "$AWK_CALL_LOG"
exec "$REAL_AWK" "$@"
STUB
cat > "$TMP_DIR/bin/date" <<'STUB'
#!/usr/bin/env bash
printf 'date\n' >> "$DATE_CALL_LOG"
exec "$REAL_DATE" "$@"
STUB
chmod +x "$TMP_DIR/bin/pgrep" "$TMP_DIR/bin/socat" "$TMP_DIR/bin/jq" "$TMP_DIR/bin/awk" "$TMP_DIR/bin/date"
python3 - "$XDG_RUNTIME_DIR/mpvsocket" <<'PY'
import socket, sys
sock = socket.socket(socket.AF_UNIX)
sock.bind(sys.argv[1])
sock.close()
PY

# Responses deliberately arrive out of order, as mpv IPC does not promise
# response order. The title contains quotes and a newline to verify that NUL
# framing cannot shift adjacent metadata fields.
export MPV_RESPONSE=$'{"request_id":4,"data":null}\n{"request_id":1,"data":"Title with \\"quotes\\" and\\nnewline"}\n{"request_id":3,"data":120}\n{"request_id":2,"data":12.5}\n'
expected_title=$'Title with "quotes" and\nnewline'
output="$("$ROOT/scripts/player" --priority mpv)"
"$REAL_JQ" -e --arg expected "$expected_title" '.player == "mpv" and .first_line == $expected and .position == "10" and .duration == "120" and .timeleft == "-01:48"' <<< "$output" >/dev/null || fail "parsed metadata did not preserve field values: $output"
# An exact half-second tie rounds to nearest-even, matching the old AWK printf
# behavior (106.5 -> 106 rather than jq's regular round result of 107).
: > "$JQ_CALL_LOG"
: > "$AWK_CALL_LOG"
: > "$DATE_CALL_LOG"
export MPV_RESPONSE=$'{"request_id":1,"data":"Half-even Track"}\n{"request_id":2,"data":13.5}\n{"request_id":3,"data":120}\n{"request_id":4,"data":null}\n'
output="$("$ROOT/scripts/player" --priority mpv)"
"$REAL_JQ" -e '.timeleft == "-01:46"' <<< "$output" >/dev/null || fail "half-even remaining-time rounding changed: $output"
call_count="$(wc -l < "$JQ_CALL_LOG")"
[[ "$call_count" -eq 2 ]] || fail "expected one batched parse + one payload serialization (2 jq calls), got $call_count"
awk_count="$(wc -l < "$AWK_CALL_LOG")"
[[ "$awk_count" -eq 0 ]] || fail "expected no awk calls for remaining-time arithmetic, got $awk_count"
date_count="$(wc -l < "$DATE_CALL_LOG" 2>/dev/null || printf '0')"
[[ "$date_count" -eq 0 ]] || fail "expected no date calls for remaining-time formatting, got $date_count"

# Null duration is intentionally kept as unknown/live metadata. Reset the
# invocation log so this case proves it still needs one parse + one serialization.
: > "$JQ_CALL_LOG"
: > "$AWK_CALL_LOG"
: > "$DATE_CALL_LOG"
export MPV_RESPONSE=$'{"request_id":1,"data":"Live Stream"}\n{"request_id":2,"data":12.5}\n{"request_id":3,"data":null}\n{"request_id":4,"data":null}\n'
output="$("$ROOT/scripts/player" --priority mpv)"
"$REAL_JQ" -e '.player == "mpv" and .first_line == "Live Stream" and .duration == "" and .timeleft == "" and .position == ""' <<< "$output" >/dev/null || fail "live stream with unknown duration was changed: $output"
call_count="$(wc -l < "$JQ_CALL_LOG")"
[[ "$call_count" -eq 2 ]] || fail "live stream expected two jq calls total, got $call_count"
awk_count="$(wc -l < "$AWK_CALL_LOG")"
[[ "$awk_count" -eq 0 ]] || fail "live stream with unknown duration must skip awk, got $awk_count calls"
date_count="$(wc -l < "$DATE_CALL_LOG" 2>/dev/null || printf '0')"
[[ "$date_count" -eq 0 ]] || fail "live stream with unknown duration must skip date, got $date_count calls"

# A duration shorter than an hour keeps the existing MM:SS display, while a
# longer duration uses HH:MM:SS. Overshooting position remains clamped to 00:00.
: > "$JQ_CALL_LOG"
: > "$AWK_CALL_LOG"
: > "$DATE_CALL_LOG"
export MPV_RESPONSE=$'{"request_id":1,"data":"Short Track"}\n{"request_id":2,"data":9.4}\n{"request_id":3,"data":60}\n{"request_id":4,"data":null}\n'
output="$("$ROOT/scripts/player" --priority mpv)"
"$REAL_JQ" -e '.timeleft == "-00:51"' <<< "$output" >/dev/null || fail "short-track remaining display changed: $output"
: > "$JQ_CALL_LOG"
export MPV_RESPONSE=$'{"request_id":1,"data":"Long Track"}\n{"request_id":2,"data":10}\n{"request_id":3,"data":3661}\n{"request_id":4,"data":null}\n'
output="$("$ROOT/scripts/player" --priority mpv)"
"$REAL_JQ" -e '.timeleft == "-01:00:51"' <<< "$output" >/dev/null || fail "long-track remaining display changed: $output"
: > "$JQ_CALL_LOG"
: > "$AWK_CALL_LOG"
: > "$DATE_CALL_LOG"
export MPV_RESPONSE=$'{"request_id":1,"data":"Overshot Track"}\n{"request_id":2,"data":90}\n{"request_id":3,"data":60}\n{"request_id":4,"data":null}\n'
output="$("$ROOT/scripts/player" --priority mpv)"
"$REAL_JQ" -e '.duration == "60" and .timeleft == "-00:00"' <<< "$output" >/dev/null || fail "remaining time should clamp to 00:00 when position exceeds duration: $output"
: > "$JQ_CALL_LOG"
export MPV_RESPONSE=$'{"request_id":1,"data":"Zero Duration"}\n{"request_id":2,"data":4}\n{"request_id":3,"data":0}\n{"request_id":4,"data":null}\n'
output="$("$ROOT/scripts/player" --priority mpv)"
"$REAL_JQ" -e '.duration == "" and .timeleft == ""' <<< "$output" >/dev/null || fail "zero duration should remain treated as unknown length: $output"
awk_count="$(wc -l < "$AWK_CALL_LOG")"
date_count="$(wc -l < "$DATE_CALL_LOG")"
[[ "$awk_count" -eq 0 && "$date_count" -eq 0 ]] || fail "remaining-time path unexpectedly invoked awk/date: awk=$awk_count date=$date_count"

printf 'mpv metadata batched parse: OK\n'
