#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
settings = (root / "Settings.qml").read_text()
metadata = (root / "js/settings/SettingsMetadata.js").read_text()
modules = (root / "components/settings/sections/SettingsModulesSection.qml").read_text()
launcher = (root / "components/launcher/Launcher.qml").read_text()
shell = (root / "shell.qml").read_text()
state = (root / "js/settings/SettingsApplyState.js").read_text()
geometry = (root / "js/settings/SettingsGeometry.js").read_text()
resets = (root / "js/settings/SettingsResets.js").read_text()

assert 'launcher: [-999999,-999999,720,640]' in settings
assert '"launcher":[-999999,-999999,720,640]' in metadata
assert 'function launcherDefaultCoordinate(index)' in modules
assert 'function writeLauncherCoordinate(index, value)' in modules
assert 'settings.geometry = geometry' in modules and 'settings.save()' in modules
assert 'value: modulesSection.launcherCoordinate(index)' in modules
assert 'Settings.geometryForLayout("launcher")' in launcher
assert 'screen: root.resolveLauncherScreen()' in launcher
assert 'function beginLayoutEdit()' in launcher and 'function endLayoutEdit()' in launcher
assert 'function beginLauncherDrag(mouse)' in launcher
assert 'root.layoutEditor.beginProxyDrag(' in launcher
assert 'Settings.endGeometryDrag("launcher", root.screenStorageName(targetScreen), localX, localY)' in launcher
assert 'item.layoutEditor = moduleLayoutEditorWindow' in shell
assert 'item.beginLayoutEdit()' in shell
assert 'monitors.launcher = String(savedMonitors.launcher)' in state
assert 'function geometryForLayout(owner, moduleName)' in geometry
assert 'geometry.launcher = profile.geometry && profile.geometry.launcher' in resets
assert 'delete monitors.launcher' in resets
print('Launcher coordinate settings, monitor persistence, smart-edit drag wiring, and profile reset: OK')
PY
node - "$ROOT/js/settings/SettingsGeometry.js" <<'JS'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const source = fs.readFileSync(process.argv[2], 'utf8').replace(/^\.pragma library\s*/m, '').replace(/^\.import .*$/mg, '');
const context = {};
vm.createContext(context);
vm.runInContext(source, context);
let saved = 0;
const owner = {
  geometry: {launcher: [-999999, -999999, 720, 640]},
  layoutEditGeometry: {},
  moduleMonitors: {},
  save() { saved++; }
};
context.beginGeometryDrag(owner, 'launcher');
context.endGeometryDrag(owner, 'launcher', 'DP-1', 210, 125);
assert.deepStrictEqual(Array.from(owner.geometry.launcher), [210, 125, 720, 640]);
assert.strictEqual(owner.moduleMonitors.launcher, 'DP-1');
assert.strictEqual(saved, 1);
console.log('Launcher geometry drag storage and target-monitor persistence: OK');
JS
node - "$ROOT/js/settings/SettingsApplyState.js" <<'JS'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const source = fs.readFileSync(process.argv[2], 'utf8').replace(/^\.pragma library\s*/m, '').replace(/^\.import .*$/mg, '');
const context = { Profiles: { SPARSE_FORMAT: 'sparse-v1', normalizeProfiles: x => x, sparsifyProfiles: x => x }, Schema: { normalizeSavedColor: (v, f) => v === undefined ? f : v } };
vm.createContext(context);
vm.runInContext(source, context);
const owner = {
  timerPresetDefaults: [5,7,15], timerPresets: [5,7,15], geometry: {launcher: [-999999,-999999,720,640]},
  moduleMonitors: {}, moduleFrames: {launcher:true}, moduleBackgrounds: {launcher:true},
  profiles: {}, customThemes: {}, themeStateRevision: 0, profileStorageFormat: 'sparse-v1',
  rebuildProfileList() {}, changed() {}
};
context.apply(owner, {}, {
  moduleMonitors: {launcher:'DP-2'},
  geometry: {launcher:[245,135,720,640]},
  profileStorageFormat: 'sparse-v1'
}, [], {launcher:true}, {launcher:true}, []);
assert.strictEqual(owner.moduleMonitors.launcher, 'DP-2', 'launcher monitor must survive settings reload');
assert.deepStrictEqual(Array.from(owner.geometry.launcher), [245,135,720,640], 'launcher coordinates must survive settings reload');
console.log('Launcher coordinate and monitor reload migration: OK');
JS
node - "$ROOT/js/settings/SettingsResets.js" <<'JS'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const source = fs.readFileSync(process.argv[2], 'utf8').replace(/^\.pragma library\s*/m, '').replace(/^\.import .*$/mg, '');
const context = {};
vm.createContext(context);
vm.runInContext(source, context);
const profile = { geometry: {launcher:[80,70,720,640]}, moduleMonitors:{launcher:'DP-2'}, moduleFrames:{launcher:false}, moduleBackgrounds:{launcher:false} };
let saves = 0;
const owner = {
  activeProfile:'work', profiles:{work:profile}, geometry:{launcher:[500,400,720,640]}, moduleMonitors:{launcher:'DP-1'},
  moduleFrames:{launcher:true}, moduleBackgrounds:{launcher:true}, defaultGeometry:{launcher:[-999999,-999999,720,640]},
  resetUnavailable() {}, save() { saves++; }
};
const config = { launcherWidth:720, launcherHeight:640 };
context.resetLauncherSettings(owner, config);
assert.deepStrictEqual(Array.from(owner.geometry.launcher), [80,70,720,640]);
assert.strictEqual(owner.moduleMonitors.launcher, 'DP-2');
assert.strictEqual(owner.moduleFrames.launcher, false);
assert.strictEqual(owner.moduleBackgrounds.launcher, false);
assert.strictEqual(saves, 1);
console.log('Launcher position, monitor, frame and background profile reset: OK');
JS
