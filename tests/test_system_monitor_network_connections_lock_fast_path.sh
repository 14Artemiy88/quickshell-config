#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/system_monitor.d/network_connections.sh"
fail() { echo "System monitor network connections lock fast path: FAIL: $*" >&2; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin"
REAL_FLOCK="$(command -v flock)"
cat > "$TMP/bin/flock" <<'WRAPPER'
#!/usr/bin/env bash
printf 'flock\n' >> "$PROCESS_LOG"
exec "$REAL_FLOCK" "$@"
WRAPPER
cat > "$TMP/bin/nmcli" <<'WRAPPER'
#!/usr/bin/env bash
printf 'nmcli\n' >> "$PROCESS_LOG"
exit 0
WRAPPER
chmod +x "$TMP/bin/flock" "$TMP/bin/nmcli"
PROCESS_LOG="$TMP/processes.log"
: > "$PROCESS_LOG"
export PROCESS_LOG REAL_FLOCK
PATH="$TMP/bin:$PATH"
export PATH

cache="$TMP/connections.json"
cache_time="$TMP/connections-time"
payload='[{"name":"cached connection","type":"wifi","status":"on"}]'
printf '%s\n' "$payload" > "$cache"
printf '%s\n' "$(( ${EPOCHSECONDS:-0} + 60 ))" > "$cache_time"
result="$(get_network_connections "$cache" "$cache_time")"
[[ "$result" == "$payload" ]] || fail "fresh cache payload changed: $result"
[[ ! -s "$PROCESS_LOG" ]] || fail "fresh cache hit launched processes: $(tr '\n' ' ' < "$PROCESS_LOG")"

# A stale cache must still take the lock and refresh once, then publish [] from
# the mocked empty nmcli result. This ensures the fast path did not bypass the
# synchronization needed for concurrent cache misses.
printf '%s\n' "$(( ${EPOCHSECONDS:-0} - 5 ))" > "$cache_time"
: > "$PROCESS_LOG"
result="$(get_network_connections "$cache" "$cache_time")"
[[ "$result" == '[]' ]] || fail "stale cache was not refreshed: $result"
lock_count="$(grep -c '^flock$' "$PROCESS_LOG" || true)"
nmcli_count="$(grep -c '^nmcli$' "$PROCESS_LOG" || true)"
[[ "$lock_count" -eq 1 ]] || fail "stale cache path should acquire one lock, got $lock_count"
[[ "$nmcli_count" -eq 1 ]] || fail "stale cache path should invoke nmcli once, got $nmcli_count"

# Refresh writes a current timestamp and result; the next request should hit
# the builtin path again without entering the lock.
: > "$PROCESS_LOG"
result="$(get_network_connections "$cache" "$cache_time")"
[[ "$result" == '[]' ]] || fail "refreshed cache payload changed: $result"
[[ ! -s "$PROCESS_LOG" ]] || fail "post-refresh cache hit launched processes: $(tr '\n' ' ' < "$PROCESS_LOG")"

echo 'System monitor network connections lock fast path: OK (no flock on fresh hits, lock retained for refresh)'
