#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/system_monitor.d/network_connections.sh"
fail() { echo "System monitor network connections: FAIL: $*" >&2; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin"
cat > "$TMP/bin/nmcli" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
[[ "${1:-}" == "-t" && "${2:-}" == "-e" && "${3:-}" == "yes" ]] || exit 2
[[ "${4:-}" == "-g" && "${5:-}" == "NAME,TYPE,DEVICE" && "${6:-}" == "c" ]] || exit 2
cat "$NMCLI_FIXTURE"
MOCK
chmod +x "$TMP/bin/nmcli"
REAL_JQ="$(command -v jq)"
cat > "$TMP/bin/jq" <<'MOCK_JQ'
#!/usr/bin/env bash
printf 'jq\n' >> "$JQ_CALL_LOG"
exec "$REAL_JQ" "$@"
MOCK_JQ
chmod +x "$TMP/bin/jq"
PATH="$TMP/bin:$PATH"
JQ_CALL_LOG="$TMP/jq-calls.log"
export PATH REAL_JQ JQ_CALL_LOG

cat > "$TMP/nmcli-fixture.txt" <<'EOF_FIXTURE'
Home "Lab":wifi:wlp2s0
Research\: VLAN:802-11-wireless:wlp3s0
Quoted \\ Profile:802-3-ethernet:enp2s0
Tabbed	Name:wifi:wlp4s0
VPN:wireguard:
Tunnel:tun:tun0
Bridge:bridge:br0
Loopback:loopback:lo
EOF_FIXTURE
export NMCLI_FIXTURE="$TMP/nmcli-fixture.txt"
: > "$JQ_CALL_LOG"
result="$(get_network_connections "$TMP/cache.json" "$TMP/cache-time")"
[[ "$(wc -l < "$JQ_CALL_LOG")" -eq 1 ]] || fail "non-empty list should invoke jq once, got $(wc -l < "$JQ_CALL_LOG") calls"
printf '%s\n' "$result" | jq -e '
  length == 5 and
  .[0].name == "Home \"Lab\"" and .[0].type == "󰖩" and .[0].status == "on" and
  .[1].name == "Research: VLAN" and .[1].type == "" and .[1].status == "on" and
  .[2].name == "Quoted \\ Profile" and .[2].type == "󰈀" and .[2].status == "on" and
  .[3].name == "Tabbed\tName" and .[3].type == "󰖩" and .[3].status == "on" and
  .[4].name == "VPN" and .[4].type == "󰠥" and .[4].status == "off"
' >/dev/null || fail "names, device status, or JSON escaping incorrect: $result"

: > "$TMP/nmcli-empty.txt"
export NMCLI_FIXTURE="$TMP/nmcli-empty.txt"
: > "$JQ_CALL_LOG"
empty="$(get_network_connections "$TMP/empty-cache.json" "$TMP/empty-cache-time")"
[[ "$empty" == '[]' ]] || fail "empty nmcli output should return [], got: $empty"
[[ ! -s "$JQ_CALL_LOG" ]] || fail "empty list should not invoke jq, got $(wc -l < "$JQ_CALL_LOG") calls"

# The cached result must remain valid JSON as well.
jq -e 'type == "array" and length == 0' "$TMP/empty-cache.json" >/dev/null || fail 'empty result was not cached as JSON'

echo 'System monitor network connections JSON escaping and parsing: OK'
