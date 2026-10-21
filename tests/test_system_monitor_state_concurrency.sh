#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "System Monitor state concurrency: FAIL: $*" >&2; exit 1; }
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# 1) Concurrent network samples must serialize the baseline read/commit.
source "$ROOT/scripts/system_monitor.d/common.sh"
source "$ROOT/scripts/system_monitor.d/network_stat.sh"
mkdir -p "$TMP/net-bin"
REAL_AWK="$(command -v awk)"
cat > "$TMP/net-bin/awk" <<'MOCK_AWK'
#!/usr/bin/env bash
set -euo pipefail
for arg in "$@"; do
    if [[ "$arg" == '-v' ]]; then
        # The arguments are supplied as separate -v name=value tokens in our
        # current implementation; inspect all arguments below as well.
        :
    fi
done
joined="$*"
if [[ "$joined" == *'pd='* && "$joined" == *'pu='* ]]; then sleep 0.2; fi
exec "$REAL_AWK" "$@"
MOCK_AWK
chmod +x "$TMP/net-bin/awk"
export REAL_AWK
export PATH="$TMP/net-bin:$PATH"
STATE="$TMP/net-state"
DEV="$TMP/net-dev"
NET_UPTIME="$TMP/net-uptime"
NET_SYSFS="$TMP/net-sys-class"
mkdir -p "$NET_SYSFS/eth0/device"
printf '2\n' > "$NET_SYSFS/eth0/ifindex"
printf '2\n' > "$NET_SYSFS/eth0/iflink"
printf '2500 1500 9900 device:4:eth0;\n' > "$STATE"
printf '100.00 100.00\n' > "$NET_UPTIME"
cat > "$DEV" <<'NET_DEV'
Inter-|   Receive                                                |  Transmit
 face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed
 lo: 900000 1 0 0 0 0 0 0 800000 1 0 0 0 0 0 0
 eth0: 3500 1 0 0 0 0 0 0 4500 1 0 0 0 0 0 0
NET_DEV
get_network_stat "$STATE" "$DEV" "$NET_UPTIME" "$NET_SYSFS" > "$TMP/net-1.json" & p1=$!
get_network_stat "$STATE" "$DEV" "$NET_UPTIME" "$NET_SYSFS" > "$TMP/net-2.json" & p2=$!
wait "$p1"; wait "$p2"
for f in "$TMP/net-1.json" "$TMP/net-2.json"; do jq -e 'type == "object" and has("speed_down") and has("speed_up")' "$f" >/dev/null || fail "invalid network JSON in $f"; done
nonzero=0
for f in "$TMP/net-1.json" "$TMP/net-2.json"; do
    if jq -e '.speed_down != "0 B/s" or .speed_up != "0 B/s"' "$f" >/dev/null; then nonzero=$((nonzero+1)); fi
done
[[ "$nonzero" == 1 ]] || fail "overlapping network polls should consume one baseline delta, got $nonzero non-zero samples"
[[ "$(cat "$STATE")" == '4500 3500 10000 device:4:eth0;' ]] || fail "network baseline/time/interface signature was not committed atomically: $(cat "$STATE")"

# 2) Parallel process snapshots must not run their stateful ps sample in parallel.
source "$ROOT/scripts/system_monitor.d/top_apps.sh"
mkdir -p "$TMP/runtime" "$TMP/ps-bin"
export XDG_RUNTIME_DIR="$TMP/runtime"
export PS_CONCURRENCY_STATE="$TMP/ps-concurrency"
cat > "$TMP/ps-bin/ps" <<'MOCK_PS'
#!/usr/bin/env bash
set -euo pipefail
state="$PS_CONCURRENCY_STATE"
lock="${state}.lock"
exec 8>"$lock"
flock -x 8
active=0; maximum=0
[[ ! -f "$state" ]] || read -r active maximum < "$state"
active=$((active+1)); (( active > maximum )) && maximum=$active
printf '%s %s\n' "$active" "$maximum" > "$state"
flock -u 8
sleep 0.15
exec 8>"$lock"
flock -x 8
read -r active maximum < "$state"
active=$((active-1))
printf '%s %s\n' "$active" "$maximum" > "$state"
MOCK_PS
chmod +x "$TMP/ps-bin/ps"
PATH="$TMP/ps-bin:$PATH"; export PATH
get_process_snapshot >/dev/null & p1=$!
get_process_snapshot >/dev/null & p2=$!
get_process_snapshot >/dev/null & p3=$!
get_process_snapshot >/dev/null & p4=$!
wait "$p1"; wait "$p2"; wait "$p3"; wait "$p4"
read -r active maximum < "$PS_CONCURRENCY_STATE"
[[ "$active" == 0 && "$maximum" == 1 ]] || fail "Top Apps samples overlapped (active=$active max=$maximum)"
top_lock="$TMP/runtime/quickshell-top-apps-cpu-$(id -u).tsv.lock"
[[ -f "$top_lock" ]] || fail 'Top Apps state lock file was not created'
[[ "$(stat -c %a "$top_lock")" == 600 ]] || fail "Top Apps lock must be mode 600, got $(stat -c %a "$top_lock")"
[[ "$(stat -c %a "$STATE.lock")" == 600 ]] || fail "network-stat lock must be mode 600, got $(stat -c %a "$STATE.lock")"

# 3) Concurrent network-connection reads should execute nmcli only once under cache lock.
source "$ROOT/scripts/system_monitor.d/network_connections.sh"
mkdir -p "$TMP/nmcli-bin"
export NMCLI_CALLS="$TMP/nmcli-calls"
export NMCLI_FIXTURE="$TMP/nmcli-fixture"
printf 'Home:wifi:wlan0\n' > "$NMCLI_FIXTURE"
cat > "$TMP/nmcli-bin/nmcli" <<'MOCK_NMCLI'
#!/usr/bin/env bash
set -euo pipefail
printf 'call\n' >> "$NMCLI_CALLS"
sleep 0.2
cat "$NMCLI_FIXTURE"
MOCK_NMCLI
chmod +x "$TMP/nmcli-bin/nmcli"
PATH="$TMP/nmcli-bin:$PATH"; export PATH
for i in 1 2 3 4; do
    get_network_connections "$TMP/connections.json" "$TMP/connections.time" > "$TMP/connections-$i.json" &
done
wait
[[ "$(wc -l < "$NMCLI_CALLS")" == 1 ]] || fail "nmcli ran more than once for concurrent cold cache"
for i in 1 2 3 4; do jq -e 'type == "array" and length == 1 and .[0].name == "Home"' "$TMP/connections-$i.json" >/dev/null || fail "bad network cache result from concurrent reader $i"; done
jq -e 'type == "array" and length == 1' "$TMP/connections.json" >/dev/null || fail 'network cache is not complete valid JSON'
[[ "$(stat -c %a "$TMP/connections.json.lock")" == 600 ]] || fail "network cache lock must be mode 600, got $(stat -c %a "$TMP/connections.json.lock")"

# The synchronization should degrade gracefully on Linux environments without flock,
# but current normal installations have it; static checks make the guarded path explicit.
grep -Fq 'flock -x 9' "$ROOT/scripts/system_monitor.d/network_stat.sh" || fail 'network state lock is missing'
grep -Fq 'flock -x 9' "$ROOT/scripts/system_monitor.d/top_apps.sh" || fail 'Top Apps state lock is missing'
grep -Fq 'flock -x 9' "$ROOT/scripts/system_monitor.d/network_connections.sh" || fail 'network cache lock is missing'

echo 'System Monitor state concurrency: OK'
