#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "Top Apps split modules: FAIL: $*" >&2; exit 1; }

settings="$ROOT/Settings.qml"
metadata="$ROOT/js/settings/SettingsMetadata.js"
state="$ROOT/js/settings/SettingsApplyState.js"
schema="$ROOT/js/settings/SettingsSchema.js"
shell="$ROOT/shell.qml"
monitor="$ROOT/services/SystemMonitor.qml"
modules="$ROOT/components/settings/sections/SettingsModulesSection.qml"
defaults="$ROOT/scripts/settings"
resets="$ROOT/js/settings/SettingsResets.js"

for key in topAppsCpu topAppsRam; do
    grep -Fq "property bool $key: true" "$settings" || fail "$key toggle is missing"
    grep -Fq "$key:" "$metadata" || fail "$key is absent from module metadata"
    grep -Fq "moduleName: \"$key\"" "$shell" || fail "$key has no independent window"
    grep -Fq "visible: Settings.$key" "$shell" || fail "$key visibility is not independent"
    grep -Fq "\"$key\":true" "$defaults" || fail "$key is absent from the default settings file"
done

! grep -Fq 'property bool topApps:' "$settings" || fail "legacy combined setting property remains"
! grep -Fq 'topApps:"' "$metadata" || fail "legacy combined module is still registered"
grep -Fq 'sectionType: "cpu"' "$shell" || fail "CPU section is not assigned to the CPU module"
grep -Fq 'sectionType: "ram"' "$shell" || fail "RAM section is not assigned to the RAM module"
grep -Fq '(Settings.topAppsCpu || Settings.topAppsRam)' "$monitor" || fail "shared monitor is not kept active when either section is enabled"
grep -Fq 'topAppsCpu:"Top Apps CPU",topAppsRam:"Top Apps RAM"' "$metadata" || fail "module labels are not distinct"
grep -Fq 'moduleName === "topAppsCpu" || moduleName === "topAppsRam"' "$resets" || fail "module reset does not support both split modules"

node - "$state" "$schema" <<'JS'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const strip = s => s.replace(/^\.pragma library\s*/m, '').replace(/^\.import .*$/mg, '');
const stateContext = {};
vm.createContext(stateContext);
vm.runInContext(strip(fs.readFileSync(process.argv[2], 'utf8')), stateContext);
stateContext.Profiles = { SPARSE_FORMAT: 'sparse-v1' };
stateContext.Schema = { normalizeSavedColor: (_value, fallback) => fallback, normalizeCustomThemes: themes => themes || {} };
stateContext.Themes = { builtinThemeNames: ['14 Theme'], palette: () => ({}) };
const schemaContext = {};
vm.createContext(schemaContext);
vm.runInContext(strip(fs.readFileSync(process.argv[3], 'utf8')), schemaContext);

assert.deepStrictEqual(JSON.parse(JSON.stringify(stateContext.migrateLegacyTopAppsMap({ topApps: false }))), { topAppsCpu: false, topAppsRam: false });
assert.deepStrictEqual(JSON.parse(JSON.stringify(stateContext.splitLegacyTopAppsGeometry([12, 20, 301, 198]))), [[12, 20, 301, 96], [12, 121, 301, 96]]);

const owner = {
  timerPresetDefaults: [5, 7, 15], timerPresets: [5, 7, 15],
  topAppsCpu: true, topAppsRam: true,
  geometry: { topAppsCpu: [5, 322, 315, 96], topAppsRam: [5, 423, 315, 96], networkStat: [5, 526, 313, 55] },
  moduleFrames: { topAppsCpu: true, topAppsRam: true },
  moduleBackgrounds: { topAppsCpu: true, topAppsRam: true },
  moduleMonitors: {}, profiles: {}, customThemes: {},
  rebuildProfileList() {}, changed() {}
};
stateContext.apply(owner, {}, {
  modules: { topApps: false },
  moduleFrames: { topApps: false },
  moduleBackgrounds: { topApps: false },
  moduleMonitors: { topApps: 'Legacy Monitor' },
  geometry: { topApps: [12, 20, 301, 198] }
}, ['topAppsCpu', 'topAppsRam'], { topAppsCpu: true, topAppsRam: true }, { topAppsCpu: true, topAppsRam: true }, []);
assert.strictEqual(owner.topAppsCpu, false);
assert.strictEqual(owner.topAppsRam, false);
assert.deepStrictEqual(JSON.parse(JSON.stringify(owner.geometry.topAppsCpu)), [12, 20, 301, 96]);
assert.deepStrictEqual(JSON.parse(JSON.stringify(owner.geometry.topAppsRam)), [12, 121, 301, 96]);
assert.strictEqual(Object.prototype.hasOwnProperty.call(owner.geometry, 'topApps'), false);
assert.strictEqual(owner.moduleFrames.topAppsCpu, false);
assert.strictEqual(owner.moduleFrames.topAppsRam, false);
assert.strictEqual(owner.moduleBackgrounds.topAppsCpu, false);
assert.strictEqual(owner.moduleBackgrounds.topAppsRam, false);
assert.strictEqual(owner.moduleMonitors.topAppsCpu, 'Legacy Monitor');
assert.strictEqual(owner.moduleMonitors.topAppsRam, 'Legacy Monitor');

const oldProfile = schemaContext.normalizeProfile({
  modules: { topApps: false },
  moduleFrames: { topApps: false },
  moduleBackgrounds: { topApps: false },
  moduleMonitors: { topApps: 'Legacy Monitor' },
  geometry: { topApps: [12, 20, 301, 198] }
}, true);
assert.deepStrictEqual(JSON.parse(JSON.stringify(oldProfile.modules)), { topAppsCpu: false, topAppsRam: false });
assert.deepStrictEqual(JSON.parse(JSON.stringify(oldProfile.geometry)), {
  topAppsCpu: [12, 20, 301, 96], topAppsRam: [12, 121, 301, 96]
});
assert.deepStrictEqual(JSON.parse(JSON.stringify(oldProfile.moduleFrames)), { topAppsCpu: false, topAppsRam: false });
assert.deepStrictEqual(JSON.parse(JSON.stringify(oldProfile.moduleBackgrounds)), { topAppsCpu: false, topAppsRam: false });
assert.deepStrictEqual(JSON.parse(JSON.stringify(oldProfile.moduleMonitors)), { topAppsCpu: 'Legacy Monitor', topAppsRam: 'Legacy Monitor' });
console.log('Top Apps split module migration: OK');
JS

echo "Top Apps split modules: OK"
