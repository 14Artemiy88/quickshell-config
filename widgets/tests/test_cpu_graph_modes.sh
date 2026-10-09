#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "CPU graph modes: FAIL: $*" >&2; exit 1; }

grep -Fq 'property string cpuGraphMode: "both"' "$ROOT/Config.qml" || fail "missing default Config property"
grep -Fq 'cpuGraphMode: "both"' "$ROOT/js/settings/SettingsDefaults.js" || fail "missing default value"
grep -Fq 'cpuGraphMode: config.cpuGraphMode' "$ROOT/js/settings/SettingsPersistence.js" || fail "mode not persisted"
grep -Fq 'Config.cpuGraphMode = ["both", "top", "bottom"].indexOf(cgm) >= 0 ? cgm : "both"' "$ROOT/js/settings/SettingsApplySystemVisual.js" || fail "mode not loaded/validated"
grep -Fq '"cpuGraphSegmentSlotWidth", "cpuGraphBarWidth", "cpuGraphMode"' "$ROOT/js/settings/SettingsResets.js" || fail "module reset missing mode"
grep -Fq 'Config.cpuGraphMode === "both"' "$ROOT/components/CpuGraph.qml" || fail "both mode renderer missing"
grep -Fq 'Config.cpuGraphMode === "top"' "$ROOT/components/CpuGraph.qml" || fail "top mode renderer missing"
grep -Fq 'Config.cpuGraphMode === "bottom"' "$ROOT/components/CpuGraph.qml" || fail "bottom mode renderer missing"
grep -Fq 'Режим графика CPU' "$ROOT/components/settings/sections/SettingsCpuRamSection.qml" || fail "settings UI missing"
node - <<'NODE' "$ROOT"
const fs=require('fs'), path=require('path');
const root=process.argv[2];
const ui=fs.readFileSync(path.join(root,'components/settings/sections/SettingsCpuRamSection.qml'),'utf8');
const expected=['Обе половины','Только верхние','Только нижние'];
if(!expected.every(x=>ui.includes(x))) { console.error('CPU graph modes: missing UI label'); process.exit(1); }
const persist=fs.readFileSync(path.join(root,'js/settings/SettingsPersistence.js'),'utf8');
const reset=fs.readFileSync(path.join(root,'js/settings/SettingsResets.js'),'utf8');
if((persist.match(/cpuGraphMode/g)||[]).length < 1 || (reset.match(/cpuGraphMode/g)||[]).length < 2) { console.error('CPU graph modes: incomplete save/reset wiring'); process.exit(1); }
console.log('CPU graph modes: OK');
NODE
