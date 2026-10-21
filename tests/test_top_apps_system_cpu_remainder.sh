#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "Top Apps system CPU remainder: FAIL: $*" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || fail 'jq is required'
RUNTIME="$(mktemp -d)"
trap 'rm -rf "$RUNTIME"' EXIT
export XDG_RUNTIME_DIR="$RUNTIME"
source "$ROOT/scripts/system_monitor.d/top_apps.sh"

fixture=$'compile\t75.0000\t1024\t101\t1\ngoland\t74.0000\t2048\t102\t1\nkwin_wayland\t24.0000\t3072\t103\t1\nzen\t18.0000\t4096\t104\t1\nspectacle\t13.4000\t512\t105\t1\nhelper\t7.0000\t256\t106\t1'
get_process_snapshot() {
    # The collector stores the global busy percentage with its baseline.
    printf 'T\t2000\nS\t2000\t3000\nL\t100.0000\n' > "$XDG_RUNTIME_DIR/quickshell-top-apps-cpu-${UID}.tsv"
    printf '%s\n' "$fixture"
}
get_cpu_capacity_percent() { if [[ -n "${1:-}" ]]; then printf -v "$1" '%s' '800.0000'; else printf '800.0000\n'; fi; }
get_total_memory_kib() { if [[ -n "${1:-}" ]]; then printf -v "$1" '%s' '32768'; else printf '32768\n'; fi; }

output="$(get_top_apps 1 0)" || fail 'CPU-only ranking failed'
jq -e '
  (.cpu | length == 5) and
  .cpu[0].name == "compile" and .cpu[0].value == "9.4%" and .cpu[0].ratio == 0.0938 and
  .cpu[1].name == "goland" and .cpu[1].value == "9.2%" and
  .cpu[2].name == "kwin_wayland" and .cpu[2].value == "3.0%" and
  .cpu[3].name == "zen" and .cpu[3].value == "2.2%" and
  .cpu[4].name == "Система/прочее" and .cpu[4].value == "76.1%" and
  .cpu[4].ratio == 0.7612 and
  (([.cpu[].ratio] | add) > 0.999 and ([.cpu[].ratio] | add) < 1.002) and
  all(.cpu[]; ((.value | rtrimstr("%") | tonumber) / 100 - .ratio | fabs) < 0.0006)
' <<< "$output" >/dev/null || fail "CPU labels/bars/remainder do not reconcile with full load: $output"

# With only half of system capacity busy, and the same four named apps, the
# residual represents only the unaccounted portion of that 50% system load.
get_process_snapshot() {
    printf 'T\t3000\nS\t2500\t3500\nL\t50.0000\n' > "$XDG_RUNTIME_DIR/quickshell-top-apps-cpu-${UID}.tsv"
    printf '%s\n' "$fixture"
}
output="$(get_top_apps 1 0)" || fail 'half-load CPU ranking failed'
jq -e '.cpu[4].name == "Система/прочее" and .cpu[4].value == "26.1%" and (([.cpu[].ratio] | add) > 0.499 and ([.cpu[].ratio] | add) < 0.502)' <<< "$output" >/dev/null || fail "remainder does not track aggregate system load: $output"

# Opting out must restore the original top-five-process list (not four apps).
output="$(get_top_apps 1 0 0)" || fail 'CPU ranking without remainder failed'
jq -e '(.cpu | length == 5) and ([.cpu[].name] | index("Система/прочее") == null) and .cpu[4].name == "spectacle"' <<< "$output" >/dev/null || fail "disabled remainder did not restore the top five groups: $output"

# The label can be customized while preserving JSON safely, including quotes.
output="$(get_top_apps 1 0 1 'Другие ресурсы "CPU"')" || fail 'CPU ranking with custom remainder label failed'
jq -e '.cpu[4].name == "Другие ресурсы \"CPU\""' <<< "$output" >/dev/null || fail "custom remainder label was not preserved: $output"

# An empty/whitespace-only label falls back to the built-in label.
output="$(get_top_apps 1 0 1 '   ')" || fail 'CPU ranking with empty label failed'
jq -e '.cpu[4].name == "Система/прочее"' <<< "$output" >/dev/null || fail "empty label fallback failed: $output"

echo 'Top Apps system CPU remainder: OK'
