#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "Top Apps Plasma-style view: FAIL: $*" >&2; exit 1; }
test_runtime_dir="$(mktemp -d)"
trap 'rm -rf "$test_runtime_dir"' EXIT
export XDG_RUNTIME_DIR="$test_runtime_dir"

ui="$ROOT/components/TopApps.qml"
source_script="$ROOT/scripts/system_monitor.d/top_apps.sh"
[[ -f "$ui" ]] || fail "TopApps.qml is missing"
[[ -f "$source_script" ]] || fail "top_apps.sh is missing"

grep -Fq 'readonly property string sectionTitle: sectionType === "ram" ? Config.topAppsRamHeaderTitle : Config.topAppsCpuHeaderTitle' "$ui" || fail "single-section configurable heading selection is missing"
grep -Fq 'property string topAppsCpuHeaderTitle: "CPU"' "$ROOT/Config.qml" || fail "default CPU heading text changed"
grep -Fq 'property string topAppsRamHeaderTitle: "ПАМЯТЬ"' "$ROOT/Config.qml" || fail "default RAM heading text changed"
grep -Fq 'readonly property string sectionSubtitle: sectionType === "ram" ? Config.topAppsRamHeaderSubtitle : Config.topAppsCpuHeaderSubtitle' "$ui" || fail "single-section configurable subtitle selection is missing"
grep -Fq 'text: root.sectionSubtitle' "$ui" || fail "header subtitle is not rendered"
grep -Fq 'property string topAppsCpuHeaderSubtitle: "ДОЛЯ ОТ ВСЕГО CPU"' "$ROOT/Config.qml" || fail "default CPU subtitle changed"
grep -Fq 'property string topAppsRamHeaderSubtitle: "ТОП ПРОЦЕССОВ"' "$ROOT/Config.qml" || fail "default RAM subtitle changed"
grep -Fq 'model: root.sectionEntries' "$ui" || fail "section entries are not rendered"
grep -Fq 'modelData.ratio' "$ui" || fail "relative usage bar is missing"
grep -Fq 'Config.topAppsRamBarColor' "$ui" || fail "RAM bar color setting is missing"
grep -Fq 'Config.topAppsCpuBarColor' "$ui" || fail "CPU bar color setting is missing"
grep -Fq 'moduleName: root.sectionModuleName' "$ui" || fail "module frame/settings integration is missing"

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
