#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "Top Apps system load built-in read: FAIL: $*" >&2; exit 1; }
source "$ROOT/scripts/system_monitor.d/top_apps.sh"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
export XDG_RUNTIME_DIR="$work/runtime"
mkdir -p "$XDG_RUNTIME_DIR"
state_file="$XDG_RUNTIME_DIR/quickshell-top-apps-cpu-${UID}.tsv"
body="$(sed -n '/^get_system_cpu_load_percent() {/,/^}/p' "$ROOT/scripts/system_monitor.d/top_apps.sh")"
! grep -Eq '(^|[[:space:]])awk([[:space:]]|$)' <<< "$body" || fail 'AWK still used to read the L state row'
grep -Fq 'while IFS=$'"'"'\t'"'"' read -r marker value _;' <<< "$body" || fail 'Bash state-row reader is missing'

compare_state() {
    local label="$1" expected actual direct captured
    expected="$(awk -F '\t' '$1 == "L" && $2 ~ /^[0-9]+([.][0-9]+)?$/ { value=$2; found=1; exit } END { if (found) { if (value < 0) value=0; if (value > 100) value=100; printf "%.4f\n", value } else print "0.0000" }' "$state_file")"
    actual="$(get_system_cpu_load_percent)"
    [[ "$actual" == "$expected" ]] || fail "$label stdout API expected $expected, got $actual"
    direct='stale-value'
    get_system_cpu_load_percent direct || fail "$label direct-assignment API returned failure"
    [[ "$direct" == "$expected" ]] || fail "$label direct API expected $expected, got $direct"
    captured_file="$work/direct-api-stdout"
    : > "$captured_file"
    get_system_cpu_load_percent direct > "$captured_file" || fail "$label second direct-assignment call failed"
    [[ "$direct" == "$expected" && ! -s "$captured_file" ]] || fail "$label direct API emitted stdout or changed value incorrectly"
}

# Missing state and missing L record keep the all-zero fallback.
rm -f "$state_file"
[[ "$(get_system_cpu_load_percent)" == '0.0000' ]] || fail 'missing state fallback changed'
missing_direct='stale'
get_system_cpu_load_percent missing_direct || fail 'missing-state direct API failed'
[[ "$missing_direct" == '0.0000' ]] || fail 'missing-state direct fallback changed'
printf 'T\t100\nS\t100\t200\n' > "$state_file"
compare_state 'missing L record'

for fixture in \
    $'T\t100\nL\t0.0000\n' \
    $'T\t100\nL\t9.1250\n' \
    $'T\t100\nL\t0009.1250\n' \
    $'T\t100\nL\t99.99999\n' \
    $'T\t100\nL\t100.0000\n' \
    $'T\t100\nL\t100.5000\n' \
    $'T\t100\nL\t999999999999999999999.0000\n' \
    $'T\t100\nL\tinvalid\nL\t42.2500\n' \
    $'T\t100\nL\t-2.0000\n'; do
    printf '%s' "$fixture" > "$state_file"
    compare_state "fixture $(printf '%q' "$fixture")"
done

# The normal valid state record is fixed-point and must retain four decimals.
printf 'T\t100\nC\t100\nS\t100\t200\nL\t42.2500\nP\t7\t8\t9\n' > "$state_file"
[[ "$(get_system_cpu_load_percent)" == '42.2500' ]] || fail 'normal state field changed'

get_top_apps_body="$(sed -n '/^get_top_apps() {/,/^}/p' "$ROOT/scripts/system_monitor.d/top_apps.sh")"
grep -Fq 'get_system_cpu_load_percent system_cpu_load_pct' <<< "$get_top_apps_body" || fail 'Top Apps caller does not use direct assignment'
! grep -Fq 'system_cpu_load_pct="$(get_system_cpu_load_percent)' <<< "$get_top_apps_body" || fail 'Top Apps still captures the state reader through command substitution'

if get_system_cpu_load_percent 'bad-name'; then
    fail 'invalid destination variable name was accepted'
fi

echo 'Top Apps system load built-in read: OK' 
