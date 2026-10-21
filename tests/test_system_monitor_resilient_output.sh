#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
fail() { echo "System Monitor resilient output: FAIL: $*" >&2; exit 1; }

# Validate each section in one shared assembly call. A malformed collector
# must fall back locally without blanking the healthy sections.
source "$ROOT/scripts/system_monitor.d/common.sh"
printf '{broken\n' > "$TMP/bad-top.json"
printf '{"down":"99 B","up":"8 B","speed_down":"2 B/s","speed_up":"1 B/s"}\n' > "$TMP/good-net.json"
printf '[{"num":"12","value":"44.0","name":"Audio"}]\n' > "$TMP/good-vol.json"
printf '{"name":false}\n' > "$TMP/bad-network.json"
actual="$(system_monitor_assemble_payload "$TMP/bad-top.json" "$TMP/good-net.json" "$TMP/good-vol.json" "$TMP/bad-network.json")"
jq -e '
    .top_apps == {cpu:[],mem:[]} and
    .net_stat.down == "99 B" and .net_stat.speed_down == "2 B/s" and
    (.volumes | length == 1 and .[0].name == "Audio") and
    .network == []
' <<< "$actual" >/dev/null || fail "bad sections were not defaulted independently: $actual"

# Each section must contain exactly one JSON document, not concatenated JSON.
printf '{"cpu":[],"mem":[]}\n{"cpu":[1],"mem":[]}\n' > "$TMP/multiple-top.json"
printf '{"down":"0 B","up":"0 B","speed_down":"0 B/s","speed_up":"0 B/s"}\n' > "$TMP/good-net-zero.json"
printf '[]\n' > "$TMP/empty-vol.json"
printf '[]\n' > "$TMP/empty-network.json"
actual="$(system_monitor_assemble_payload "$TMP/multiple-top.json" "$TMP/good-net-zero.json" "$TMP/empty-vol.json" "$TMP/empty-network.json")"
jq -e '.top_apps == {cpu:[],mem:[]} and .volumes == [] and .network == []' <<< "$actual" >/dev/null \
    || fail "multiple JSON documents did not use fallback: $actual"

# Integration test: run the real coordinator against stub collectors; verify
# one broken collector does not blank the other results and assembly starts jq
# exactly once (rather than once per section plus one final invocation).
mkdir -p "$TMP/integration/scripts/system_monitor.d" "$TMP/home" "$TMP/runtime" \
    "$TMP/config" "$TMP/data" "$TMP/state" "$TMP/cache" "$TMP/jq-bin"
cp "$ROOT/scripts/system_monitor" "$TMP/integration/scripts/system_monitor"
cp "$ROOT/scripts/env" "$TMP/integration/scripts/env"
cp "$ROOT/scripts/system_monitor.d/common.sh" "$TMP/integration/scripts/system_monitor.d/common.sh"
cat > "$TMP/integration/scripts/system_monitor.d/network_stat.sh" <<'STUB'
get_network_stat() { printf '{"down":"99 B","up":"8 B","speed_down":"2 B/s","speed_up":"1 B/s"}\n'; }
STUB
cat > "$TMP/integration/scripts/system_monitor.d/top_apps.sh" <<'STUB'
get_top_apps() { printf '{broken\n'; return 1; }
STUB
cat > "$TMP/integration/scripts/system_monitor.d/volumes.sh" <<'STUB'
get_volumes() { printf '[{"num":"12","value":"44.0","name":"Audio"}]\n'; }
STUB
cat > "$TMP/integration/scripts/system_monitor.d/network_connections.sh" <<'STUB'
get_network_connections() { printf '{"name":false}\n'; return 1; }
STUB
REAL_JQ="$(command -v jq)"
export REAL_JQ
export JQ_COUNTER_FILE="$TMP/jq-count"
cat > "$TMP/jq-bin/jq" <<'WRAPPER'
#!/usr/bin/env bash
printf 'x\n' >> "$JQ_COUNTER_FILE"
exec "$REAL_JQ" "$@"
WRAPPER
chmod +x "$TMP/jq-bin/jq"
export HOME="$TMP/home"
export XDG_CONFIG_HOME="$TMP/config"
export XDG_DATA_HOME="$TMP/data"
export XDG_STATE_HOME="$TMP/state"
export XDG_CACHE_HOME="$TMP/cache"
export XDG_RUNTIME_DIR="$TMP/runtime"
output="$(PATH="$TMP/jq-bin:$PATH" bash "$TMP/integration/scripts/system_monitor" 1 1 1 1)"
call_count="$(wc -l < "$JQ_COUNTER_FILE")"
[[ "$call_count" == 1 ]] || fail "coordinator ran jq $call_count times instead of once"
jq -e '
    type == "object" and
    (.top_apps.cpu == [] and .top_apps.mem == []) and
    (.net_stat.down == "99 B" and .net_stat.speed_down == "2 B/s") and
    (.volumes | length == 1 and .[0].name == "Audio") and
    (.network == [])
' <<< "$output" >/dev/null || fail "coordinator did not preserve healthy sections: $output"

echo 'System Monitor resilient output: OK'
