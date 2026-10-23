#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
config = (root / "Config.qml").read_text(encoding="utf-8")
settings = (root / "Settings.qml").read_text(encoding="utf-8")
metadata = (root / "js/settings/SettingsMetadata.js").read_text(encoding="utf-8")
modules = (root / "components/settings/sections/SettingsModulesSection.qml").read_text(encoding="utf-8")
general = (root / "components/settings/sections/SettingsGeneralSection.qml").read_text(encoding="utf-8")
player = (root / "components/settings/sections/SettingsPlayerSection.qml").read_text(encoding="utf-8")
window = (root / "components/settings/sections/SettingsWindowSection.qml").read_text(encoding="utf-8")
widget_window = (root / "components/WidgetWindow.qml").read_text(encoding="utf-8")
launcher = (root / "components/launcher/Launcher.qml").read_text(encoding="utf-8")
shell = (root / "shell.qml").read_text(encoding="utf-8")
persist = (root / "js/settings/SettingsPersistence.js").read_text(encoding="utf-8")
apply_state = (root / "js/settings/SettingsApplyState.js").read_text(encoding="utf-8")
apply_player = (root / "js/settings/SettingsApplyTimerPlayer.js").read_text(encoding="utf-8")
resets = (root / "js/settings/SettingsResets.js").read_text(encoding="utf-8")

assert 'property var moduleBlurEnabled:' in settings
assert 'readonly property var defaultModuleBlurEnabled: SettingsMetadata.defaultModuleBlurEnabled' in settings
assert 'function setModuleBlurEnabled(moduleName, enabled)' in settings
assert 'settings.moduleBlurEnabled[moduleRow.moduleName] === true' in modules
assert 'settings.setModuleBlurEnabled(moduleRow.moduleName, checked)' in modules
assert 'settings.moduleBlurEnabled.launcher === true' in modules
assert 'settings.setModuleBlurEnabled("launcher", checked)' in modules
assert 'text: "Блюр"' in modules
assert 'text: "Блюр окна настроек"' in window
assert 'settings.setModuleBlurEnabled("settings", checked)' in window
assert 'property int backgroundBlurRadius: 10' in config
assert 'targetProperty: "backgroundBlurRadius"' in general
assert 'heading: "Размытие фона"' in general
assert 'moduleName: "settings"' in shell, 'the settings window must use its own blur switch'
assert 'Settings.moduleBlurEnabled[root.moduleName] === true' in widget_window
assert 'radius: Math.max(0, root.backgroundBlurRadius)' in widget_window
assert 'Settings.moduleBlurEnabled.launcher === true ? launcherBox : null' in launcher
assert 'radius: Math.max(0, Config.backgroundBlurRadius)' in launcher
assert 'backgroundBlurRadius: config.backgroundBlurRadius' in persist
assert 'moduleBlurEnabled: owner.moduleBlurEnabled' in persist
assert 'o.backgroundBlurRadius !== undefined ? o.backgroundBlurRadius : o.playerBlurRadius' in apply_player
assert 'savedBlurEnabled.player === undefined && o.playerBlurEnabled !== undefined' in apply_state
assert 'settingsBorder' in (root / "js/settings/SettingsMetadata.js").read_text(encoding="utf-8")
assert 'label: "Цвет рамки окна настроек"' in window
assert 'targetProperty: "settingsBorder"' in window
assert 'border.color: Config.settingsBorder' in (root / "components/settings/SettingsWidget.qml").read_text(encoding="utf-8")
assert 'playerBlurEnabledBox' not in player and 'playerBlurRadiusField' not in player, 'Player-specific blur UI must be removed'
assert 'blur.settings = profile.moduleBlurEnabled' in resets, 'settings-window blur must restore with its settings tab'
assert 'blurValues.settings = (owner.moduleBlurEnabled || {}).settings' in resets, 'resetting module list must not reset settings-window blur'
print("Per-module blur controls, shared radius, Player migration, profile persistence and Settings Window blur: OK")
PY
node - "$ROOT/js/settings/SettingsApplyState.js" <<'JS'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const source = fs.readFileSync(process.argv[2], 'utf8')
  .replace(/^\.pragma library\s*/m, '')
  .replace(/^\.import .*$/mg, '');
const context = {
  Profiles: { SPARSE_FORMAT: 'sparse-v1', normalizeProfiles: x => x, sparsifyProfiles: x => x, completeLegacySnapshot: (defaults, profile) => profile },
  Schema: { normalizeSavedColor: (v, fallback) => v === undefined ? fallback : v, normalizeProfiles: x => x, normalizeCustomThemes: x => x || {} },
  Themes: { builtinThemeNames: ['14 Theme'], palette: () => ({}) }
};
vm.createContext(context);
vm.runInContext(source, context);
function owner() {
  return {
    moduleBlurEnabled: { time:false, calendar:false, player:false, launcher:false, settings:false },
    moduleNames: ['time', 'calendar', 'player'], moduleFrames:{}, moduleBackgrounds:{}, moduleMonitors:{},
    profiles:{}, customThemes:{}, activeProfile:'', activeTheme:'14 Theme', themeStateRevision:0,
    rebuildProfileList() {}, changed() {}
  };
}
function apply(saved) {
  const o = owner();
  const config = { playerBlurEnabled:false };
  context.apply(o, config, saved, o.moduleNames, {time:true,calendar:true,player:true}, {time:true,calendar:true,player:true}, [], {time:false,calendar:false,player:false,launcher:false,settings:false});
  return {o, config};
}
let result = apply({moduleBlurEnabled:{time:true,player:true,launcher:true,settings:true}});
assert.strictEqual(result.o.moduleBlurEnabled.time, true);
assert.strictEqual(result.o.moduleBlurEnabled.player, true);
assert.strictEqual(result.o.moduleBlurEnabled.launcher, true);
assert.strictEqual(result.o.moduleBlurEnabled.settings, true);
assert.strictEqual(result.config.playerBlurEnabled, true);
result = apply({playerBlurEnabled:true});
assert.strictEqual(result.o.moduleBlurEnabled.player, true, 'legacy Player checkbox migrates into the per-module map');
assert.strictEqual(result.o.moduleBlurEnabled.launcher, false);
assert.strictEqual(result.o.moduleBlurEnabled.settings, false);
result = apply({moduleBlurEnabled:{player:false}, playerBlurEnabled:true});
assert.strictEqual(result.o.moduleBlurEnabled.player, false, 'new map overrides the legacy Player flag');
console.log('Per-module blur settings load, legacy Player migration, and new-map precedence: OK');
JS
