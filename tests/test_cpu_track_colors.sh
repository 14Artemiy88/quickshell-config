#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "CPU per-bar track colors: FAIL: $*" >&2; exit 1; }

CONFIG="$ROOT/Config.qml"
DEFAULTS="$ROOT/js/settings/SettingsDefaults.js"
PERSIST="$ROOT/js/settings/SettingsPersistence.js"
APPLY="$ROOT/js/settings/SettingsApplySystemVisual.js"
RESETS="$ROOT/js/settings/SettingsResets.js"
WIDGET="$ROOT/components/CpuWidget.qml"
CPU_UI="$ROOT/components/settings/sections/SettingsCpuRamSection.qml"
THEME_UI="$ROOT/components/settings/sections/SettingsColorsSection.qml"
THEMES="$ROOT/js/settings/SettingsThemes.js"
META="$ROOT/js/settings/SettingsMetadata.js"
SCHEMA="$ROOT/js/settings/SettingsSchema.js"

for obsolete in cpuBarTrackColor cpuRamBarTrackColor; do
    if grep -RqF "$obsolete" "$CONFIG" "$DEFAULTS" "$PERSIST" "$APPLY" "$RESETS" "$WIDGET" "$CPU_UI"; then
        fail "obsolete standalone setting $obsolete remains in the implementation"
    fi
done

for i in {1..8}; do
    key="cpu${i}Track"
    grep -Fq "property color $key:" "$CONFIG" || fail "$key Config property is missing"
    grep -Fq "$key:" "$DEFAULTS" || fail "$key default is missing"
    grep -Fq "\"$key\"" "$META" || fail "$key is missing from theme color metadata"
    grep -Fq "\"$key\"" "$THEME_UI" || fail "$key is missing from theme editor"
done

expected='trackColor: index === 8 ? Config.ramTrack : root.trackColors[index % root.trackColors.length]'
[[ "$(grep -Fc "$expected" "$WIDGET")" -eq 2 ]] || fail "both horizontal and vertical CPU layouts must map each core to its own track color"
grep -Fq 'property var trackColors: [Config.cpu1Track, Config.cpu2Track, Config.cpu3Track, Config.cpu4Track, Config.cpu5Track, Config.cpu6Track, Config.cpu7Track, Config.cpu8Track]' "$WIDGET" || fail "per-core track color array is missing"
if grep -Fq 'heading: "Цвета фона дорожек"' "$CPU_UI"; then fail "v981 separate CPU track settings group is still present"; fi
if grep -Fq 'cpuBarTrackColor' "$CPU_UI"; then fail "obsolete CPU track setting remains in CPU settings UI"; fi
grep -Fq '"Полосы CPU и RAM"' "$THEME_UI" || fail "theme palette group for CPU/RAM bars is missing"
grep -Fq 'cpu1Track: "CPU 1: неактивный фон"' "$THEME_UI" || fail "CPU 1 inactive track label is missing"
grep -Fq 'ramTrack: "RAM: неактивный фон"' "$THEME_UI" || fail "RAM inactive track label is missing"
grep -Fq '/^cpu[1-8]Track$/.test(fallbackKey)' "$SCHEMA" || fail "legacy custom palettes do not migrate per-core tracks from metricTrack"

node - "$ROOT" <<'JS'
const fs = require('fs');
const vm = require('vm');
const path = require('path');
const root = process.argv[2];
const source = fs.readFileSync(path.join(root, 'js/settings/SettingsThemes.js'), 'utf8')
  .replace(/^\.pragma library\s*/m, '').replace(/^\.import .*$/mg, '');
const context = {}; vm.createContext(context); vm.runInContext(source, context);
for (const name of context.builtinThemeNames) {
  const palette = context.palette(name, {});
  for (let i = 1; i <= 8; i++) {
    if (typeof palette[`cpu${i}Track`] !== 'string' || !palette[`cpu${i}Track`])
      throw new Error(`${name}: cpu${i}Track missing`);
  }
}
console.log(`All ${context.builtinThemeNames.length} built-in themes contain eight CPU track colors: OK`);
JS

echo "CPU per-bar track colors: OK"
