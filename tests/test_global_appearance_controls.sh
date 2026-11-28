#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'NODE'
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const root = process.argv[2];
const read = file => fs.readFileSync(path.join(root, file), 'utf8');
const stripQmlJs = source => source
  .replace(/^\.pragma library\s*/m, '')
  .replace(/^\.import .*$/gm, '');

const configQml = read('Config.qml');
const defaults = read('js/settings/SettingsDefaults.js');
const persistence = read('js/settings/SettingsPersistence.js');
const applyCoreSource = stripQmlJs(read('js/settings/SettingsApplyCore.js'));
const schemaSource = stripQmlJs(read('js/settings/SettingsSchema.js'));
const profilesSource = stripQmlJs(read('js/settings/SettingsProfiles.js'));
const resets = read('js/settings/SettingsResets.js');
const settings = read('Settings.qml');
const navigation = read('components/settings/SettingsNavigationController.qml');
const general = read('components/settings/sections/SettingsInterfaceSection.qml');

const keys = [
  'cornerRadiusScale', 'buttonBordersEnabled', 'inputBordersEnabled',
  'popupBordersEnabled', 'cardBordersEnabled'
];
for (const key of keys) {
  assert.ok(configQml.includes(`property ${key === 'cornerRadiusScale' ? 'int' : 'bool'} ${key}:`), `${key} is declared in Config`);
  assert.ok(defaults.includes(`${key}:`), `${key} has a default`);
  assert.ok(persistence.includes(`${key}: config.${key}`) || persistence.includes(`${key}: config.${key} !== false`), `${key} is captured in profile snapshots`);
  assert.ok(resets.includes(`"${key}"`), `${key} is restored by Interface reset`);
}
assert.match(configQml, /function scaledCornerRadius\(baseRadius\)[\s\S]*?Math\.max\(50, Math\.min\(150, scale\)\)/,
  'shared radius helper clamps its scale to 50–150%');
const helper = configQml.match(/function scaledCornerRadius\(baseRadius\)\s*\{[\s\S]*?\n    \}/)?.[0];
assert.ok(helper, 'radius helper can be extracted for deterministic verification');
let radiusContext = { cornerRadiusScale: 100 };
vm.runInNewContext(helper + '\nvar result = [scaledCornerRadius(4), scaledCornerRadius(7)];', radiusContext);
assert.deepEqual(Array.from(radiusContext.result), [4, 7], '100% keeps all existing component radii unchanged');
radiusContext = { cornerRadiusScale: 50 };
vm.runInNewContext(helper + '\nvar result = [scaledCornerRadius(4), scaledCornerRadius(7)];', radiusContext);
assert.deepEqual(Array.from(radiusContext.result), [2, 4], '50% reduces existing component radii proportionally');
radiusContext = { cornerRadiusScale: 150 };
vm.runInNewContext(helper + '\nvar result = [scaledCornerRadius(4), scaledCornerRadius(7)];', radiusContext);
assert.deepEqual(Array.from(radiusContext.result), [6, 11], '150% increases existing component radii proportionally');

function loadLibrary(source, extra = {}) {
  const sandbox = { ...extra };
  vm.runInNewContext(source, sandbox);
  return sandbox;
}
const Schema = loadLibrary(schemaSource);
const oldFull = Schema.normalizeProfile({ fontSize: 12 }, false);
assert.deepEqual(
  [oldFull.cornerRadiusScale, oldFull.buttonBordersEnabled, oldFull.inputBordersEnabled, oldFull.popupBordersEnabled, oldFull.cardBordersEnabled],
  [100, true, true, true, true],
  'legacy full profiles restore the neutral radius and borders-on appearance'
);
const sparse = Schema.normalizeProfile({}, true);
for (const key of keys) assert.equal(sparse[key], undefined, `${key} remains inherited in sparse profiles`);
const malformed = Schema.normalizeProfile({ cornerRadiusScale: 999, buttonBordersEnabled: 0, inputBordersEnabled: false }, false);
assert.deepEqual(
  [malformed.cornerRadiusScale, malformed.buttonBordersEnabled, malformed.inputBordersEnabled, malformed.popupBordersEnabled, malformed.cardBordersEnabled],
  [150, true, false, true, true],
  'profile normalization clamps the radius and safely normalizes border toggles'
);

const Core = loadLibrary(applyCoreSource, { Schema });
const cfg = { cornerRadiusScale: 100, buttonBordersEnabled: true, inputBordersEnabled: true, popupBordersEnabled: true, cardBordersEnabled: true };
Core.apply({}, cfg, { cornerRadiusScale: 125, buttonBordersEnabled: false, inputBordersEnabled: false, popupBordersEnabled: true, cardBordersEnabled: false });
assert.deepEqual(
  [cfg.cornerRadiusScale, cfg.buttonBordersEnabled, cfg.inputBordersEnabled, cfg.popupBordersEnabled, cfg.cardBordersEnabled],
  [125, false, false, true, false],
  'profile application restores all appearance settings'
);
Core.apply({}, cfg, { cornerRadiusScale: 1, buttonBordersEnabled: 'false' });
assert.deepEqual([cfg.cornerRadiusScale, cfg.buttonBordersEnabled], [50, true], 'runtime profile application clamps invalid radius and normalizes booleans');

const Profiles = loadLibrary(profilesSource);
for (const key of keys)
  assert.equal(Profiles.profileSavePathMatches({}, 'general', null, [key]), true, `${key} belongs to the existing general profile scope exposed by Appearance → Interface`);
assert.ok(settings.includes('cornerRadiusScale') && settings.includes('buttonBordersEnabled'), 'Settings reset visibility recognizes global appearance overrides');
assert.ok(navigation.includes('interface: "general"'), 'Interface page dirty-state uses the preserved General profile scope');
assert.ok(general.includes('changeKeys: ({ keys: ["frameBorderWidth", "frameRadius", "cornerRadiusScale", "buttonBordersEnabled", "inputBordersEnabled", "popupBordersEnabled", "cardBordersEnabled"] })'),
  'appearance controls share the Interface page save/reset actions');
for (const label of ['Рамки кнопок', 'Рамки полей ввода', 'Рамки всплывающих окон', 'Рамки карточек'])
  assert.ok(general.includes(label), `Settings UI exposes ${label}`);

const qmlExpectations = [
  ['components/settings/primitives/SettingsButton.qml', 'Config.buttonBordersEnabled', 'button border toggle'],
  ['components/primitives/HoverButtonSurface.qml', 'Config.buttonBordersEnabled', 'shared icon-button border toggle'],
  ['components/primitives/StyledTextButton.qml', 'Config.buttonBordersEnabled', 'styled button border toggle'],
  ['components/settings/primitives/SettingsInputField.qml', 'Config.inputBordersEnabled', 'input border toggle'],
  ['components/settings/primitives/SettingsCheckBox.qml', 'Config.inputBordersEnabled', 'checkbox border toggle'],
  ['components/settings/primitives/SettingsComboBox.qml', 'Config.inputBordersEnabled', 'combo input border toggle'],
  ['components/settings/primitives/SettingsComboBox.qml', 'Config.popupBordersEnabled', 'combo popup border toggle'],
  ['components/Dashboard.qml', 'Config.popupBordersEnabled', 'Dashboard filter popup border toggle'],
  ['components/Dashboard.qml', 'Config.buttonBordersEnabled', 'Dashboard action button border toggle'],
  ['components/Dashboard.qml', 'radius: Config.scaledCornerRadius(9)\n            activeFocusOnTab: root.historyViewActive', 'Dashboard history navigation control corner scaling'],
  ['components/Dashboard.qml', 'Config.inputBordersEnabled', 'Dashboard history search and filter checkbox border toggle'],
  ['components/Dashboard.qml', 'Config.cardBordersEnabled ? (modelData.unread === true ? 2 : 1) : 0', 'Dashboard notification history card border toggle'],
  ['components/Dashboard.qml', 'root.dashboardFrameVisible && Config.cardBordersEnabled ? Config.frameBorderWidth : 0', 'Dashboard outer frame respects both global card toggle and zero border width'],
  ['components/mopidy/Mopidy.qml', 'Config.buttonBordersEnabled && Config.mopidyHoverMode === "frame"', 'Mopidy hover frame border toggle'],
  ['components/launcher/Launcher.qml', 'Config.popupBordersEnabled', 'Launcher popup border toggle'],
  ['components/TimerOptions.qml', 'Config.popupBordersEnabled', 'Timer options popup border toggle'],
  ['components/osd/SystemOsd.qml', 'Config.popupBordersEnabled', 'System OSD popup border toggle'],
  ['shell.qml', 'Config.popupBordersEnabled ? Config.frameBorderWidth : 0', 'timer finished popup border toggle'],
  ['components/launcher/Launcher.qml', 'searchField.activeFocus ? 1 : (Config.inputBordersEnabled ? 1 : 0)', 'Launcher search input border toggle'],
  ['components/settings/sections/SettingsWeatherSection.qml', 'Config.cardBordersEnabled ? 1 : 0', 'Weather wind direction settings card border toggle'],
  ['components/settings/primitives/SettingsNavigationFolder.qml', 'Config.cardBordersEnabled ? 1 : 0', 'Settings navigation folder card border toggle'],
  ['components/settings/sections/SettingsTimersSection.qml', '(Config.inputBordersEnabled || timerFinishedImagePathField.activeFocus) ? 1 : 0', 'custom SettingsTextField background respects input border toggle'],
  ['components/mopidy/MopidyLibraryView.qml', '(Config.inputBordersEnabled || searchField.activeFocus) ? 1 : 0', 'Mopidy library search input border toggle'],
  ['components/mopidy/MopidyPlaylistDialog.qml', '(Config.inputBordersEnabled || playlistDialogField.activeFocus) ? 1 : 0', 'Mopidy playlist dialog input border toggle'],
  ['components/mopidy/MopidyFileBrowser.qml', '(Config.inputBordersEnabled || fileFilterField.activeFocus) ? 1 : 0', 'Mopidy file filter input border toggle'],
  ['components/primitives/ModuleFrame.qml', 'Config.cardBordersEnabled', 'module card border toggle'],
  ['components/settings/SettingsWidget.qml', 'Config.cardBordersEnabled', 'Settings window card border toggle'],
  ['components/notifications/Notifications.qml', 'Config.cardBordersEnabled', 'notification card border toggle'],
  ['components/osd/SystemOsd.qml', 'Config.popupBordersEnabled', 'OSD popup border toggle'],
  ['components/settings/primitives/SettingsGroup.qml', 'Config.cardBordersEnabled', 'settings group card border toggle']
];
for (const [file, token, description] of qmlExpectations)
  assert.ok(read(file).includes(token), `${description} is wired into its shared component`);
for (const file of [
  'components/settings/primitives/SettingsButton.qml',
  'components/primitives/HoverButtonSurface.qml',
  'components/Dashboard.qml',
  'components/launcher/Launcher.qml',
  'components/TimerOptions.qml',
  'components/settings/primitives/SettingsNavigationFolder.qml',
  'components/settings/primitives/SettingsInputField.qml',
  'components/settings/primitives/SettingsComboBox.qml',
  'components/primitives/ModuleFrame.qml',
  'components/notifications/Notifications.qml',
  'components/osd/SystemOsd.qml'
]) assert.ok(read(file).includes('Config.scaledCornerRadius('), `${file} uses proportional shared corner-radius scaling`);
assert.ok(read('components/settings/primitives/SettingsInputField.qml').includes('root.activeFocus'), 'input focus outline remains available when idle borders are disabled');
assert.ok(read('components/settings/primitives/SettingsButton.qml').includes('root.activeFocus'), 'button focus outline remains available when idle borders are disabled');
assert.ok(!read('components/settings/primitives/SettingsButton.qml').includes('Config.buttonBordersEnabled || root.emphasized'),
  'the global button border toggle also applies to emphasized buttons, while focus remains explicit');

// Caller-provided SettingsTextField/ComboBox backgrounds must not bypass the
// shared input-border control. Search only the settings section backgrounds,
// preserving visual borders for non-input previews and swatches.
const walk = dir => fs.readdirSync(path.join(root, dir), { withFileTypes: true }).flatMap(entry => {
  const rel = path.join(dir, entry.name);
  return entry.isDirectory() ? walk(rel) : (entry.isFile() && rel.endsWith('.qml') ? [rel] : []);
});
for (const file of walk('components/settings/sections')) {
  const lines = read(file).split(/\r?\n/);
  for (let i = 0; i < lines.length; i++) {
    if (/border\.width:\s*1\s*;?/.test(lines[i])) {
      const context = lines.slice(Math.max(0, i - 5), i + 1).join('\n');
      if (context.includes('background: Rectangle') && /\b[A-Za-z_]\w*\.activeFocus/.test(context))
        assert.fail(`${file}:${i + 1} has a focusable custom input background that bypasses inputBordersEnabled`);
    }
  }
}
console.log('PASS: global radius scaling, independent border categories, profile/sparse persistence, reset scope, and shared QML primitives are integrated.');
NODE
