#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
mkdir -p "$TMP_DIR/bin"
REAL_JQ="$(command -v jq)"
export REAL_JQ CURL_LOG="$TMP_DIR/curl-calls" JQ_CALL_LOG="$TMP_DIR/jq-calls"
export PATH="$TMP_DIR/bin:$PATH"
ITERATIONS="${1:-25}"
[[ "$ITERATIONS" =~ ^[1-9][0-9]*$ ]] || { echo "Usage: $0 [iterations]" >&2; exit 2; }

cat > "$TMP_DIR/bin/curl" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
printf 'curl\n' >> "$CURL_LOG"
data=''
while (($#)); do
    case "$1" in
        -d) data="${2:-}"; shift 2 ;;
        *) shift ;;
    esac
done
if [[ "$data" == *'"id":5'* && "$data" == *'core.tracklist.get_single'* ]]; then
    printf '[{"id":1,"result":63},{"id":2,"result":false},{"id":3,"result":true},{"id":4,"result":false},{"id":5,"result":true}]\n'
elif [[ "$data" == *'core.mixer.get_volume'* ]]; then
    printf '{"id":1,"result":63}\n'
elif [[ "$data" == *'core.mixer.get_mute'* ]]; then
    printf '{"id":1,"result":false}\n'
elif [[ "$data" == *'core.tracklist.get_random'* ]]; then
    printf '{"id":1,"result":true}\n'
elif [[ "$data" == *'core.tracklist.get_repeat'* ]]; then
    printf '{"id":1,"result":false}\n'
elif [[ "$data" == *'core.tracklist.get_single'* ]]; then
    printf '{"id":1,"result":true}\n'
else
    printf '{}\n'
fi
STUB
cat > "$TMP_DIR/bin/jq" <<'STUB'
#!/usr/bin/env bash
printf 'jq\n' >> "$JQ_CALL_LOG"
exec "$REAL_JQ" "$@"
STUB
chmod +x "$TMP_DIR/bin/curl" "$TMP_DIR/bin/jq"

run_before() {
    local i
    for ((i=0; i<ITERATIONS; i++)); do
        "$ROOT/scripts/mopidy/mixer.sh" get >/dev/null
        "$ROOT/scripts/mopidy/playback.sh" state >/dev/null
    done
}
run_after() {
    local i
    for ((i=0; i<ITERATIONS; i++)); do
        "$ROOT/scripts/mopidy/status.sh" state >/dev/null
    done
}
measure() {
    local name="$1"; shift
    : > "$CURL_LOG"; : > "$JQ_CALL_LOG"
    local start end elapsed curl_count jq_count
    start="$(date +%s%N)"
    "$@"
    end="$(date +%s%N)"
    elapsed=$(( (end - start) / 1000000 ))
    curl_count="$(wc -l < "$CURL_LOG")"
    jq_count="$(wc -l < "$JQ_CALL_LOG")"
    printf '%s\t%s\t%s\t%s\n' "$name" "$elapsed" "$curl_count" "$jq_count"
}
printf 'Mopidy status polling benchmark (mock JSON-RPC, %s iterations)\n' "$ITERATIONS"
printf 'phase\telapsed_ms\tcurl_calls\tjq_calls\n'
measure before run_before
measure after run_after
