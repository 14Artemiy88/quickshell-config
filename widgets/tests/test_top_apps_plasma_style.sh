#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "Top Apps Plasma-style view: FAIL: $*" >&2; exit 1; }

ui="$ROOT/components/TopApps.qml"
source_script="$ROOT/scripts/system_monitor.d/top_apps.sh"
[[ -f "$ui" ]] || fail "TopApps.qml is missing"
[[ -f "$source_script" ]] || fail "top_apps.sh is missing"

grep -Fq 'title: "CPU"' "$ui" || fail "CPU section heading is missing"
grep -Fq 'title: "ПАМЯТЬ"' "$ui" || fail "memory section heading is missing"
grep -Fq 'model: sectionFrame.section.entries' "$ui" || fail "section entries are not rendered"
grep -Fq 'modelData.ratio' "$ui" || fail "relative usage bar is missing"
grep -Fq 'Config.ram' "$ui" || fail "memory section color is missing"
grep -Fq 'Config.accent' "$ui" || fail "CPU section color is missing"
grep -Fq 'moduleName: "topApps"' "$ui" || fail "module frame/settings integration is missing"

# Exercise the real data producer: it must work without bc, emit valid JSON,
# preserve name/value/pid, include a numeric 0..1 ratio and cap each list at 5.
command -v jq >/dev/null 2>&1 || fail "jq is required by the project but unavailable in this test environment"
output="$(bash -c 'source "$1"; get_top_apps' _ "$source_script")" || fail "top_apps.sh did not execute"
printf '%s\n' "$output" | jq -e '
  type == "object" and
  (.cpu | type == "array" and length <= 5 and all(.[]; (.name|type)=="string" and (.value|type)=="string" and (.pid|type)=="string" and (.processCount|type)=="number" and .processCount >= 1 and (.ratio|type)=="number" and .ratio >= 0 and .ratio <= 1)) and
  (.mem | type == "array" and length <= 5 and all(.[]; (.name|type)=="string" and (.value|type)=="string" and (.pid|type)=="string" and (.processCount|type)=="number" and .processCount >= 1 and (.ratio|type)=="number" and .ratio >= 0 and .ratio <= 1)) and
  all(.cpu[]; (.value | test("%$"))) and
  all(.mem[]; (.value | test("(Kb|Mb|Gb)$")))
' >/dev/null || fail "JSON schema or usage ratios are invalid"

# There should be no external bc invocation in this producer; awk handles
# formatting, which avoids empty values if bc is absent.
if grep -Eq '(^|[[:space:]])bc([[:space:]]|$)' "$source_script"; then
    fail "top_apps.sh still depends on bc"
fi

echo "Top Apps Plasma-style view: OK"
