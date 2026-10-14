#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/system_monitor.d/common.sh"
source "$ROOT/scripts/system_monitor.d/network_stat.sh"
fail() { echo "System monitor network stat baseline: FAIL: $*" >&2; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
STATE="$TMP/state"
DEV="$TMP/net-dev"
UPTIME="$TMP/uptime"
SYSFS="$TMP/sys-class-net"
mkdir -p "$SYSFS/eth0/device" "$SYSFS/wlan0/device" "$SYSFS/tun0" "$SYSFS/veth0"
printf '2\n' > "$SYSFS/eth0/ifindex"
printf '2\n' > "$SYSFS/eth0/iflink"
printf '3\n' > "$SYSFS/wlan0/ifindex"
printf '3\n' > "$SYSFS/wlan0/iflink"
printf '11\n' > "$SYSFS/tun0/ifindex"
printf '2\n' > "$SYSFS/tun0/iflink"
printf '12\n' > "$SYSFS/veth0/ifindex"
printf '8\n' > "$SYSFS/veth0/iflink"

write_dev() {
    local lo_rx="$1" lo_tx="$2" eth_rx="$3" eth_tx="$4"
    local tun_rx="${5:-100000}" tun_tx="${6:-200000}"
    cat > "$DEV" <<EOF_DEV
Inter-|   Receive                                                |  Transmit
 face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed
  lo: $lo_rx 1 0 0 0 0 0 0 $lo_tx 1 0 0 0 0 0 0
 eth0: $eth_rx 1 0 0 0 0 0 0 $eth_tx 1 0 0 0 0 0 0
 tun0: $tun_rx 1 0 0 0 0 0 0 $tun_tx 1 0 0 0 0 0 0
 veth0: 8000000 1 0 0 0 0 0 0 9000000 1 0 0 0 0 0 0
EOF_DEV
}
assert_json() {
    local json="$1" expression="$2" description="$3"
    jq -e "$expression" <<< "$json" >/dev/null || fail "$description: $json"
}

# First invocation establishes counter and monotonic-time baselines.
printf '10.00 10.00\n' > "$UPTIME"
write_dev 900000 800000 1500 2500
actual="$(get_network_stat "$STATE" "$DEV" "$UPTIME" "$SYSFS")"
assert_json "$actual" '.down == "1.46 KB" and .up == "2.44 KB" and .speed_down == "0 B/s" and .speed_up == "0 B/s"' 'first sample should establish a zero-rate baseline'
[[ "$(cat "$STATE")" == '2500 1500 1000 device:4:eth0;' ]] || fail "unexpected initial counters/timestamp/interface signature: $(cat "$STATE")"

# The second invocation reports a rate normalized by elapsed seconds, not raw
# bytes per poll. 2000 bytes over 2 seconds becomes 1000 B/s.
printf '12.00 12.00\n' > "$UPTIME"
write_dev 900100 800100 3500 4500 10100000 10200000
actual="$(get_network_stat "$STATE" "$DEV" "$UPTIME" "$SYSFS")"
assert_json "$actual" '.down == "3.41 KB" and .up == "4.39 KB" and .speed_down == "1000 B/s" and .speed_up == "1000 B/s"' 'second sample should report bytes per second'

# Different poll intervals must use elapsed time, not raw bytes per sample.
printf '12.50 12.50\n' > "$UPTIME"
write_dev 900150 800150 4000 5000
actual="$(get_network_stat "$STATE" "$DEV" "$UPTIME" "$SYSFS")"
assert_json "$actual" '.speed_down == "1000 B/s" and .speed_up == "1000 B/s"' 'same 500 bytes over half a second should preserve the rate'

# Interface/counter reset should not create negative or huge speed values.
printf '14.00 14.00\n' > "$UPTIME"
write_dev 900200 800200 500 600
actual="$(get_network_stat "$STATE" "$DEV" "$UPTIME" "$SYSFS")"
assert_json "$actual" '.speed_down == "0 B/s" and .speed_up == "0 B/s"' 'counter reset should clamp speed to zero'

# A corrupt state file is treated as a fresh baseline rather than a speed spike.
printf 'not-a-counter nope\n' > "$STATE"
printf '16.00 16.00\n' > "$UPTIME"
write_dev 900300 800300 9000000 8000000
actual="$(get_network_stat "$STATE" "$DEV" "$UPTIME" "$SYSFS")"
assert_json "$actual" '.speed_down == "0 B/s" and .speed_up == "0 B/s"' 'invalid state should start a new baseline'

# Legacy state formats have no interface signature, so the first upgraded
# sample safely establishes a new rate baseline before comparing interfaces.
printf '123 456\n' > "$STATE"
actual="$(get_network_stat "$STATE" "$DEV" "$UPTIME" "$SYSFS")"
assert_json "$actual" '.speed_down == "0 B/s" and .speed_up == "0 B/s"' 'legacy state should start a fresh rate baseline'
[[ "$(wc -w < "$STATE")" -eq 4 ]] || fail 'legacy state was not upgraded with time and interface signature'

# State created by v675 stored the monotonic timestamp but not the interface
# signature. It is upgraded safely with one zero-rate baseline sample.
LEGACY_RATE_STATE="$TMP/legacy-rate-state"
printf '456 123 1600\n' > "$LEGACY_RATE_STATE"
actual="$(get_network_stat "$LEGACY_RATE_STATE" "$DEV" "$UPTIME" "$SYSFS")"
assert_json "$actual" '.speed_down == "0 B/s" and .speed_up == "0 B/s"' 'legacy three-field state should establish interface-aware baseline'
[[ "$(wc -w < "$LEGACY_RATE_STATE")" -eq 4 ]] || fail 'legacy timestamp state was not upgraded with interface signature'

# Reordering lines in /proc/net/dev does not change a normalized interface
# signature and therefore does not discard a valid speed sample.
ORDER_STATE="$TMP/order-state"
ORDER_DEV="$TMP/order-net-dev"
write_order_dev() {
    local order="$1" eth_rx="$2" eth_tx="$3" wlan_rx="$4" wlan_tx="$5"
    {
        printf 'Inter-|   Receive                                                |  Transmit\n'
        printf ' face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed\n'
        printf ' lo: 0 1 0 0 0 0 0 0 0 1 0 0 0 0 0 0\n'
        if [[ "$order" == 'wlan-first' ]]; then
            printf ' wlan0: %s 1 0 0 0 0 0 0 %s 1 0 0 0 0 0 0\n' "$wlan_rx" "$wlan_tx"
            printf ' eth0: %s 1 0 0 0 0 0 0 %s 1 0 0 0 0 0 0\n' "$eth_rx" "$eth_tx"
        else
            printf ' eth0: %s 1 0 0 0 0 0 0 %s 1 0 0 0 0 0 0\n' "$eth_rx" "$eth_tx"
            printf ' wlan0: %s 1 0 0 0 0 0 0 %s 1 0 0 0 0 0 0\n' "$wlan_rx" "$wlan_tx"
        fi
    } > "$ORDER_DEV"
}
printf '40.00 40.00\n' > "$UPTIME"
write_order_dev wlan-first 1000 2000 2000 3000
actual="$(get_network_stat "$ORDER_STATE" "$ORDER_DEV" "$UPTIME" "$SYSFS")"
assert_json "$actual" '.speed_down == "0 B/s" and .speed_up == "0 B/s"' 'two interface sample should establish baseline'
printf '41.00 41.00\n' > "$UPTIME"
write_order_dev eth-first 1500 2500 2500 3500
actual="$(get_network_stat "$ORDER_STATE" "$ORDER_DEV" "$UPTIME" "$SYSFS")"
assert_json "$actual" '.speed_down == "1000 B/s" and .speed_up == "1000 B/s"' 'interface line reorder must preserve the rate baseline'

# Unavailable source should return valid JSON and not overwrite the last state.
cp "$STATE" "$TMP/state-before-missing"
actual="$(get_network_stat "$STATE" "$TMP/missing-net-dev" "$UPTIME" "$SYSFS")"
assert_json "$actual" '.down == "0 B" and .up == "0 B" and .speed_down == "0 B/s" and .speed_up == "0 B/s"' 'missing source should return safe zero data'
cmp -s "$STATE" "$TMP/state-before-missing" || fail 'missing source should not overwrite the previous counters'

# Switching from one device-backed NIC to another must reset the rate
# baseline. Otherwise the old NIC's cumulative counters can be subtracted from
# the new NIC's unrelated counters and appear as a huge traffic spike.
SWITCH_STATE="$TMP/state-switch"
SWITCH_DEV="$TMP/net-dev-switch"
write_switch_dev() {
    local iface="$1" rx="$2" tx="$3"
    cat > "$SWITCH_DEV" <<EOF_SWITCH
Inter-|   Receive                                                |  Transmit
 face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed
 lo: 0 1 0 0 0 0 0 0 0 1 0 0 0 0 0 0
 $iface: $rx 1 0 0 0 0 0 0 $tx 1 0 0 0 0 0 0
EOF_SWITCH
}
printf '30.00 30.00\n' > "$UPTIME"
write_switch_dev eth0 1000 2000
actual="$(get_network_stat "$SWITCH_STATE" "$SWITCH_DEV" "$UPTIME" "$SYSFS")"
assert_json "$actual" '.speed_down == "0 B/s" and .speed_up == "0 B/s"' 'initial NIC should establish a zero-rate baseline'
[[ "$(cat "$SWITCH_STATE")" == '2000 1000 3000 device:4:eth0;' ]] || fail "unexpected Ethernet interface signature: $(cat "$SWITCH_STATE")"
printf '32.00 32.00\n' > "$UPTIME"
write_switch_dev wlan0 900000000 800000000
actual="$(get_network_stat "$SWITCH_STATE" "$SWITCH_DEV" "$UPTIME" "$SYSFS")"
assert_json "$actual" '.speed_down == "0 B/s" and .speed_up == "0 B/s"' 'changing active NIC should reset speed baseline instead of reporting a false spike'
[[ "$(cat "$SWITCH_STATE")" == '800000000 900000000 3200 device:5:wlan0;' ]] || fail "Wi-Fi interface did not become the new baseline: $(cat "$SWITCH_STATE")"
printf '33.00 33.00\n' > "$UPTIME"
write_switch_dev wlan0 900001000 800001000
actual="$(get_network_stat "$SWITCH_STATE" "$SWITCH_DEV" "$UPTIME" "$SYSFS")"
assert_json "$actual" '.speed_down == "1000 B/s" and .speed_up == "1000 B/s"' 'rate should resume normally after the new NIC baseline is established'

# Virtual-interface counters must not duplicate traffic when a device-backed
# physical interface is available. The increasing tun0/veth0 counters above
# are intentionally excluded; the reported rate follows eth0 only.
# If sysfs exposes no device-backed interfaces (minimal container fallback),
# all non-loopback interfaces remain countable so the monitor does not go dark.
EMPTY_SYSFS="$TMP/empty-sysfs"
mkdir -p "$EMPTY_SYSFS/eth0" "$EMPTY_SYSFS/tun0"
printf '1.00 1.00\n' > "$UPTIME"
write_dev 0 0 1000 2000 3000 4000
fallback_actual="$(get_network_stat "$TMP/fallback-state" "$DEV" "$UPTIME" "$EMPTY_SYSFS")"
assert_json "$fallback_actual" '.down == "7.63 MB" and .up == "8.58 MB"' 'no-device sysfs fallback should retain non-loopback totals'

echo 'System monitor network stat baseline: OK'
