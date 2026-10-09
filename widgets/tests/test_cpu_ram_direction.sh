#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "CPU/RAM direction: FAIL: $*" >&2; exit 1; }

for f in Config.qml js/settings/SettingsDefaults.js js/settings/SettingsPersistence.js js/settings/SettingsApplySystemVisual.js js/settings/SettingsResets.js components/MetricBar.qml components/CpuWidget.qml components/settings/sections/SettingsCpuRamSection.qml; do
    test -f "$ROOT/$f" || fail "missing $f"
done

grep -Fq 'property string cpuBarDirection: "leftToRight"' "$ROOT/Config.qml" || fail "missing Config default"
grep -Fq 'cpuBarDirection: "leftToRight"' "$ROOT/js/settings/SettingsDefaults.js" || fail "missing settings default"
grep -Fq 'cpuBarDirection: config.cpuBarDirection' "$ROOT/js/settings/SettingsPersistence.js" || fail "direction not persisted"
grep -Fq 'Config.cpuBarDirection = ["leftToRight", "rightToLeft", "topToBottom", "bottomToTop"].indexOf(cbd) >= 0 ? cbd : "leftToRight"' "$ROOT/js/settings/SettingsApplySystemVisual.js" || fail "direction not loaded/validated"
grep -Fq '"cpuBarDirection"' "$ROOT/js/settings/SettingsResets.js" || fail "direction not in resets/profile application"
grep -Fq 'root.direction === "rightToLeft"' "$ROOT/components/MetricBar.qml" || fail "right-to-left renderer missing"
grep -Fq 'root.direction === "bottomToTop"' "$ROOT/components/MetricBar.qml" || fail "bottom-to-top renderer missing"
grep -Fq 'Config.cpuBarDirection === "topToBottom"' "$ROOT/components/CpuWidget.qml" || fail "vertical layout missing"
grep -Fq 'Направление заполнения полос' "$ROOT/components/settings/sections/SettingsCpuRamSection.qml" || fail "direction setting UI missing"
node - "$ROOT" <<'NODE'
const fs = require('fs'), path = require('path');
const root = process.argv[2];
const ui = fs.readFileSync(path.join(root, 'components/settings/sections/SettingsCpuRamSection.qml'), 'utf8');
const labels = ['Слева направо', 'Справа налево', 'Сверху вниз', 'Снизу вверх'];
if (!labels.every(s => ui.includes(s))) { console.error('CPU/RAM direction: incomplete labels'); process.exit(1); }
const widget = fs.readFileSync(path.join(root, 'components/CpuWidget.qml'), 'utf8');
if (!widget.includes('Config.cpuShowRam ? 9 : 8')) { console.error('CPU/RAM direction: RAM-aware vertical meter count missing'); process.exit(1); }
console.log('CPU/RAM direction: OK');
NODE
