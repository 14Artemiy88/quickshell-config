#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
modules="$ROOT/components/settings/sections/SettingsModulesSection.qml"
launcher="$ROOT/components/launcher/Launcher.qml"
settings="$ROOT/Settings.qml"
metadata="$ROOT/js/settings/SettingsMetadata.js"
state="$ROOT/js/settings/SettingsApplyState.js"
resets="$ROOT/js/settings/SettingsResets.js"
persist="$ROOT/js/settings/SettingsPersistence.js"

# Both indicators are real controls backed by the shared persisted module maps.
grep -Fq 'id: launcherFrameBox' "$modules"
grep -Fq 'checked: settings.moduleFrames.launcher !== false' "$modules"
grep -Fq 'values.launcher = checked' "$modules"
grep -Fq 'id: launcherBackgroundBox' "$modules"
grep -Fq 'checked: settings.moduleBackgrounds.launcher !== false' "$modules"
! grep -Fq 'text: "—"' "$modules"

# The actual launcher surface responds live to the same toggles.
grep -Fq 'Settings.moduleBackgrounds.launcher !== false' "$launcher"
grep -Fq 'Settings.moduleFrames.launcher !== false' "$launcher"
grep -Fq 'theme.launcherBackground : theme.transparent' "$launcher"
grep -Fq '? Config.frameBorderWidth : 0' "$launcher"

grep -Fq 'launcher:true' "$settings"
grep -Fq '"launcher":true' "$metadata"
grep -Fq 'moduleFrames: owner.moduleFrames, moduleBackgrounds: owner.moduleBackgrounds' "$persist"

node - "$state" "$resets" <<'JS'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const strip = s => s.replace(/^\.pragma library\s*/m, '').replace(/^\.import .*$/mg, '');

const state = {};
vm.createContext(state);
vm.runInContext(strip(fs.readFileSync(process.argv[2], 'utf8')), state);
state.Profiles = { SPARSE_FORMAT: 'sparse-v1' };
state.Schema = { normalizeSavedColor: (_value, fallback) => fallback };
const owner = {
  timerPresetDefaults: [5,7,15], timerPresets: [5,7,15],
  geometry: {}, moduleFrames: {time:true, launcher:true}, moduleBackgrounds: {time:true, launcher:true},
  moduleMonitors: {}, profiles: {}, customThemes: {}, themeStateRevision: 0,
  rebuildProfileList() {}, changed() {}
};
state.apply(owner, {}, {
  moduleFrames: {time:false, launcher:false},
  moduleBackgrounds: {time:false, launcher:false}
}, ['time'], {time:true, launcher:true}, {time:true, launcher:true}, []);
assert.strictEqual(owner.moduleFrames.launcher, false, 'saved launcher frame flag must survive reload');
assert.strictEqual(owner.moduleBackgrounds.launcher, false, 'saved launcher background flag must survive reload');
assert.strictEqual(owner.moduleFrames.time, false);
assert.strictEqual(owner.moduleBackgrounds.time, false);

// Old settings without launcher keys retain the visible/default state.
state.apply(owner, {}, {}, ['time'], {time:true, launcher:true}, {time:true, launcher:true}, []);
assert.strictEqual(owner.moduleFrames.launcher, true, 'legacy config should default launcher frame on');
assert.strictEqual(owner.moduleBackgrounds.launcher, true, 'legacy config should default launcher background on');

const resets = {};
vm.createContext(resets);
vm.runInContext(strip(fs.readFileSync(process.argv[3], 'utf8')), resets);
const profile = { moduleFrames: {launcher:false}, moduleBackgrounds: {launcher:false} };
const resetOwner = {
  activeProfile: 'default', profiles: {default:profile}, moduleFrames:{launcher:true}, moduleBackgrounds:{launcher:true},
  save() {}, resetUnavailable() {}
};
resets.resetLauncherSettings(resetOwner, {});
assert.strictEqual(resetOwner.moduleFrames.launcher, false, 'launcher reset must restore profile frame flag');
assert.strictEqual(resetOwner.moduleBackgrounds.launcher, false, 'launcher reset must restore profile background flag');
console.log('Launcher frame/background persistence and reset: OK');
JS

echo 'Launcher Frame/Background integration: OK'
