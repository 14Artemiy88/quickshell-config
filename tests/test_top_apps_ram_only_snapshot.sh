#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "Top Apps RAM-only snapshot: FAIL: $*" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || fail 'jq is required'
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/runtime" "$TMP/bin" "$TMP/proc"
export XDG_RUNTIME_DIR="$TMP/runtime"
export TOP_APPS_PROC_ROOT="$TMP/proc"
export MOCK_PS_FIXTURE="$TMP/ps-fixture"
cat > "$MOCK_PS_FIXTURE" <<'FIXTURE'
101 1 4096 ram-app
202 1 2048 second-app
FIXTURE
export MOCK_PS_FIXTURE
cat > "$TMP/bin/ps" <<'MOCK_PS'
#!/usr/bin/env bash
set -euo pipefail
cat "$MOCK_PS_FIXTURE"
MOCK_PS
chmod +x "$TMP/bin/ps"
PATH="$TMP/bin:$PATH"
export PATH
source "$ROOT/scripts/system_monitor.d/top_apps.sh"
uid="$(id -u)"
state="$XDG_RUNTIME_DIR/quickshell-top-apps-cpu-${uid}.tsv"
# A previous CPU baseline must be cleared while only RAM is polled, otherwise
# re-enabling CPU much later would report an average over the inactive period.
printf 'T\t999999\nP\t101\t12345\t800\n' > "$state"

snapshot="$(get_process_snapshot 0)" || fail 'RAM-only snapshot failed'
jq_input="$(printf '%s\n' "$snapshot" | awk -F '\t' 'NF != 5 || $2 != "0.0000" { exit 1 } END { if (NR != 2) exit 1; print "ok" }')" || fail "RAM-only rows are malformed: $snapshot"
[[ "$jq_input" == ok ]] || fail 'RAM-only snapshot did not return both fixture processes'
printf '%s\n' "$snapshot" | awk -F '\t' '$1 == "ram-app" && $3 == 4096 && $4 == 101 && $5 == 1 {found=1} END {exit !found}' || fail "RSS/PID/PPID fields changed: $snapshot"
[[ "$(cat "$state")" == $'T\t-1' ]] || fail "RAM-only poll did not reset stale CPU baseline: $(cat "$state")"

# CPU polling remains supported when matching /proc stat records are present.
mkdir -p "$TOP_APPS_PROC_ROOT/101"
cat > "$TOP_APPS_PROC_ROOT/101/stat" <<'STAT'
101 (ram-app) S 1 101 101 0 0 0 0 0 0 0 100 0 0 0 20 0 1 0 12345 8192 4
STAT
cpu_snapshot="$(get_process_snapshot 1)" || fail 'CPU-enabled snapshot failed'
printf '%s\n' "$cpu_snapshot" | awk -F '\t' '$1 == "ram-app" && NF == 7 && $6 == "-" {found=1} END {exit !found}' || fail "CPU-enabled snapshot failed to read stat data: $cpu_snapshot"
grep -Fqx $'P\t101\t12345\t100' "$state" || fail "CPU-enabled poll did not store the new baseline: $(cat "$state")"

echo 'Top Apps RAM-only snapshot: OK'
