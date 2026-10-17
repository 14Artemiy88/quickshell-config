#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/system_monitor.d/network_connections.sh"
fail() { echo "System monitor network connections cache fast path: FAIL: $*" >&2; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin"
PROCESS_LOG="$TMP/processes.log"
: > "$PROCESS_LOG"
export PROCESS_LOG

# Wrap commands that should not be needed for a valid cache hit. Resolve real
# paths before putting wrappers first in PATH so the wrappers cannot recurse.
REAL_DATE="$(command -v date)"
REAL_CAT="$(command -v cat)"
REAL_AWK="$(command -v awk)"
REAL_JQ="$(command -v jq)"
for cmd in date cat awk jq; do
    case "$cmd" in
        date) real="$REAL_DATE" ;;
        cat) real="$REAL_CAT" ;;
        awk) real="$REAL_AWK" ;;
        jq) real="$REAL_JQ" ;;
    esac
    cat > "$TMP/bin/$cmd" <<WRAPPER
#!/usr/bin/env bash
printf '%s\\n' '$cmd' >> "\$PROCESS_LOG"
exec '$real' "\$@"
WRAPPER
    chmod +x "$TMP/bin/$cmd"
done
cat > "$TMP/bin/nmcli" <<'WRAPPER'
#!/usr/bin/env bash
printf '%s\n' 'nmcli' >> "$PROCESS_LOG"
exit 99
WRAPPER
chmod +x "$TMP/bin/nmcli"

cache="$TMP/cache.json"
cache_time="$TMP/cache-time"
payload='[{"name":"cached connection","type":"wifi","status":"on"}]'
printf '%s\n' "$payload" > "$cache"
# A comfortably future timestamp keeps the fixture on the cache-hit path even
# if the test runs across a wall-clock second boundary.
printf '%s\n' "$(( ${EPOCHSECONDS:-0} + 60 ))" > "$cache_time"

PATH="$TMP/bin:$PATH"
export PATH
result="$(get_network_connections "$cache" "$cache_time")"
[[ "$result" == "$payload" ]] || fail "cache payload changed: $result"
[[ ! -s "$PROCESS_LOG" ]] || fail "cache hit launched external utilities: $(tr '\n' ' ' < "$PROCESS_LOG")"

echo 'System monitor network connections cache fast path: OK (no date/cat/nmcli/awk/jq on cache hit)'
