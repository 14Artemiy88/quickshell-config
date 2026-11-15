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
assert 'notifications' in (root / 'js/settings/SettingsMetadata.js').read_text(encoding='utf-8')
assert 'settings.moduleBlurEnabled[moduleRow.moduleName] === true' in modules
assert 'settings.setModuleBlurEnabled(moduleRow.moduleName, checked)' in modules
assert 'settings.moduleBlurEnabled.launcher === true' in modules
assert 'settings.setModuleBlurEnabled("launcher", checked)' in modules
assert 'text: "Блюр"' in modules
assert 'text: "Блюр окна настроек"' in window
assert 'settings.setModuleBlurEnabled("settings", checked)' in window
assert 'property int backgroundBlurRadius: 10' in config
assert '"notifications":true' in metadata.split('var defaultModuleFrames = ', 1)[1].splitlines()[0]
assert '"notifications":true' in metadata.split('var defaultModuleBackgrounds = ', 1)[1].splitlines()[0]
assert '"notifications":false' in metadata.split('var defaultModuleBlurEnabled = ', 1)[1].splitlines()[0]
assert 'targetProperty: "backgroundBlurRadius"' in general
assert 'heading: "Размытие фона"' in general
assert 'moduleName: "settings"' in shell, 'the settings window must use its own blur switch'
assert 'Settings.moduleBlurEnabled[root.moduleName] === true' in widget_window
assert 'radius: Math.max(0, root.backgroundBlurRadius)' in widget_window
notifications = (root / "components/notifications/Notifications.qml").read_text(encoding="utf-8")
assert 'Settings.moduleBlurEnabled.notifications === true' in notifications and 'notificationList : layoutEditPreview' in notifications
assert 'radius: Math.max(0, Config.backgroundBlurRadius)' in notifications
assert 'Settings.moduleBackgrounds.notifications !== false ? Config.background : Config.transparent' in notifications
assert 'Settings.moduleFrames.notifications !== false ? Math.max(1, Config.frameBorderWidth) : 0' in notifications
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
assert 'owner.defaultModuleFrames[moduleName]' in resets and 'owner.defaultModuleBackgrounds[moduleName]' in resets, 'module resets fall back to appearance defaults for older profiles'
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
    moduleBlurEnabled: { time:false, calendar:false, player:false, notifications:false, launcher:false, settings:false },
    moduleNames: ['time', 'calendar', 'player', 'notifications'], moduleFrames:{}, moduleBackgrounds:{}, moduleMonitors:{},
    profiles:{}, customThemes:{}, activeProfile:'', activeTheme:'14 Theme', themeStateRevision:0,
    rebuildProfileList() {}, changed() {}
  };
}
function apply(saved) {
  const o = owner();
  const config = { playerBlurEnabled:false };
  context.apply(o, config, saved, o.moduleNames, {time:true,calendar:true,player:true,notifications:true}, {time:true,calendar:true,player:true,notifications:true}, [], {time:false,calendar:false,player:false,notifications:false,launcher:false,settings:false});
  return {o, config};
}
let result = apply({moduleBlurEnabled:{time:true,player:true,launcher:true,settings:true}});
assert.strictEqual(result.o.moduleBlurEnabled.time, true);
assert.strictEqual(result.o.moduleBlurEnabled.player, true);
assert.strictEqual(result.o.moduleBlurEnabled.launcher, true);
assert.strictEqual(result.o.moduleBlurEnabled.settings, true);
assert.strictEqual(result.o.moduleFrames.notifications, true, 'notification frame default is loaded for older settings files');
assert.strictEqual(result.o.moduleBackgrounds.notifications, true, 'notification background default is loaded for older settings files');
assert.strictEqual(result.o.moduleBlurEnabled.notifications, false, 'notification blur defaults to disabled');
assert.strictEqual(result.config.playerBlurEnabled, true);
result = apply({playerBlurEnabled:true});
assert.strictEqual(result.o.moduleBlurEnabled.player, true, 'legacy Player checkbox migrates into the per-module map');
assert.strictEqual(result.o.moduleBlurEnabled.launcher, false);
assert.strictEqual(result.o.moduleBlurEnabled.settings, false);
result = apply({moduleBlurEnabled:{player:false}, playerBlurEnabled:true});
assert.strictEqual(result.o.moduleBlurEnabled.player, false, 'new map overrides the legacy Player flag');
console.log('Per-module blur settings load, legacy Player migration, and new-map precedence: OK');
JS
node - "$ROOT/js/settings/SettingsResets.js" <<'JS'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const source = fs.readFileSync(process.argv[2], 'utf8');
const context = {};
vm.createContext(context);
vm.runInContext(source + '\nthis.resetModule = resetModule;', context);
const owner = {
  activeProfile: 'legacy',
  profiles: { legacy: { modules: {} } },
  expandedProfileData(name) { return this.profiles[name]; },
  defaultModuleFrames: { notifications: true },
  defaultModuleBackgrounds: { notifications: true },
  defaultModuleBlurEnabled: { notifications: false },
  defaultGeometry: { notifications: [-999999, 16, 380, 0] },
  moduleFrames: { notifications: false },
  moduleBackgrounds: { notifications: false },
  moduleBlurEnabled: { notifications: true },
  moduleMonitors: {},
  geometry: { notifications: [50, 70, 460, 250] },
  save() {},
  resetUnavailable() {}
};
const config = { notificationsCardWidth: 460 };
context.resetModule(owner, config, 'notifications');
assert.strictEqual(owner.moduleFrames.notifications, true, 'legacy profiles reset notification frame to the built-in default');
assert.strictEqual(owner.moduleBackgrounds.notifications, true, 'legacy profiles reset notification background to the built-in default');
assert.strictEqual(owner.moduleBlurEnabled.notifications, false, 'legacy profiles reset notification blur to the built-in default');
assert.deepStrictEqual(Array.from(owner.geometry.notifications), [-999999, 16, 380, 0], 'module reset restores the notification geometry baseline');
console.log('Notifications appearance reset with profiles predating the new switches: OK');
JS
