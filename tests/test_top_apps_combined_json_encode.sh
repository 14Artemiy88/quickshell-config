#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { printf 'Top Apps combined JSON encode: FAIL: %s\n' "$*" >&2; exit 1; }
source "$ROOT/scripts/system_monitor.d/top_apps.sh"
REAL_JQ="$(command -v jq)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
mkdir -p "$TMP/bin"
cat > "$TMP/bin/jq" <<'WRAP'
#!/usr/bin/env bash
printf 'jq\n' >> "$TOP_APPS_JQ_LOG"
exec "$REAL_JQ" "$@"
WRAP
chmod +x "$TMP/bin/jq"
export REAL_JQ TOP_APPS_JQ_LOG="$TMP/jq.log"
export PATH="$TMP/bin:$PATH"

# Use deterministic snapshots while keeping the production aggregation and
# formatting functions under test.
get_process_snapshot() {
    printf 'app "alpha"\t12.3456\t2048\t101\t1\t-\t-\napp-beta\t34.5000\t4096\t202\t1\t-\t-\n'
}
get_cpu_capacity_percent() { printf -v "$1" '%s' '800.0000'; }
get_system_cpu_load_percent() { printf -v "$1" '%s' '40.0000'; }
get_total_memory_kib() { printf -v "$1" '%s' '16384'; }

# Both CPU and RAM enabled must encode the final object with one jq invocation.
: > "$TOP_APPS_JQ_LOG"
out="$(get_top_apps 1 1 0)" || fail 'combined CPU/RAM poll failed'
[[ "$(wc -l < "$TOP_APPS_JQ_LOG")" -eq 1 ]] || fail "combined poll used $(wc -l < "$TOP_APPS_JQ_LOG") jq calls, expected one"
"$REAL_JQ" -e '
  (.cpu | length) == 2 and (.mem | length) == 2 and
  .cpu[0].name == "app-beta" and .cpu[1].name == "app \"alpha\"" and
  .mem[0].name == "app-beta" and .mem[0].value == "4.0 Mb" and
  (.cpu[0].processCount | type) == "number" and (.mem[0].ratio | type) == "number"
' <<< "$out" >/dev/null || fail "output schema/value mismatch: $out"

# A disabled section remains [] while still sharing the same single encoder.
: > "$TOP_APPS_JQ_LOG"
out="$(get_top_apps 1 0 0)" || fail 'CPU-only poll failed'
[[ "$(wc -l < "$TOP_APPS_JQ_LOG")" -eq 1 ]] || fail 'CPU-only poll should use one jq call'
"$REAL_JQ" -e '(.cpu|length)==2 and .mem==[]' <<< "$out" >/dev/null || fail "CPU-only schema mismatch: $out"

: > "$TOP_APPS_JQ_LOG"
out="$(get_top_apps 0 1 0)" || fail 'RAM-only poll failed'
[[ "$(wc -l < "$TOP_APPS_JQ_LOG")" -eq 1 ]] || fail 'RAM-only poll should use one jq call'
"$REAL_JQ" -e '.cpu==[] and (.mem|length)==2' <<< "$out" >/dev/null || fail "RAM-only schema mismatch: $out"

: > "$TOP_APPS_JQ_LOG"
out="$(get_top_apps 0 0 0)" || fail 'empty poll failed'
[[ "$(wc -l < "$TOP_APPS_JQ_LOG")" -eq 1 ]] || fail 'empty poll should use one jq call'
[[ "$out" == '{"cpu":[],"mem":[]}' || "$out" == '{"mem":[],"cpu":[]}' ]] || fail "empty schema mismatch: $out"

# The high-frequency combined poll should call the batched encoder, not the
# two per-section JSON wrappers followed by a third JSON-assembly jq.
get_body="$(sed -n '/^get_top_apps() {/,/^}/p' "$ROOT/scripts/system_monitor.d/top_apps.sh")"
[[ "$get_body" == *'format_top_apps_rows_tsv'* && "$get_body" == *'format_top_apps_payload_json'* ]] || fail 'get_top_apps is not using TSV + combined JSON path'
[[ "$get_body" != *'format_top_apps_rows_json'* ]] || fail 'per-section JSON wrapper reintroduced in hot path'

echo 'Top Apps combined JSON encoder: one jq per combined/CPU-only/RAM-only/empty poll, schema parity OK'
