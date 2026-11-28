#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'NODE'
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const assert = require('assert');
const root = process.argv[2];
const read = name => fs.readFileSync(path.join(root, name), 'utf8');
function load(name, extra = {}) {
  const source = read(name).replace(/^\s*\.pragma library\s*/m, '').replace(/^\s*\.import .*$/gm, '');
  const context = { ...extra };
  vm.runInNewContext(source, context, { filename: name });
  return context;
}

const configSource = read('Config.qml');
const defaultsSource = read('js/settings/SettingsDefaults.js');
const persistenceSource = read('js/settings/SettingsPersistence.js');
const notificationsSource = read('components/notifications/Notifications.qml');
const settingsSource = read('components/settings/sections/SettingsNotificationsSection.qml');
const navSource = read('components/settings/SettingsNavigationController.qml');
const checksSource = read('CHECK.sh');
const apply = load('js/settings/SettingsApplyCore.js', { Config: {}, Schema: { normalizeSavedColor: (v, f) => v || f } });
const schema = load('js/settings/SettingsSchema.js');
const profiles = load('js/settings/SettingsProfiles.js');
const resets = load('js/settings/SettingsResets.js');

assert.match(configSource, /property string notificationsBodyFont: ""/,
  'empty body font must preserve the system/application default');
assert.match(defaultsSource, /notificationsBodyFont: ""/,
  'body font must have a profile default');
assert.ok(persistenceSource.includes('notificationsBodyFont: config.notificationsBodyFont'),
  'body font must survive profile save/load');

const bodyFamilyBindings = notificationsSource.match(/font\.family: Config\.resolveFontFamily\(Config\.notificationsBodyFont\)/g) || [];
assert.strictEqual(bodyFamilyBindings.length, 2,
  'visible body text and hidden height-measure text must both resolve empty overrides to the generic system family');
assert.ok(configSource.includes('function resolveFontFamily(overrideFamily)'), 'Config exposes a shared generic system font resolver');
assert.ok(settingsSource.includes('targetProperty: "notificationsBodyFont"'),
  'notification settings must expose the body font override');
assert.ok(settingsSource.includes('settingsSearchId: "notifications-body-font"'),
  'body font must be discoverable in Settings search');
assert.ok(settingsSource.includes('placeholderText: "Системный шрифт"'),
  'empty font must explain that it inherits the system font');
assert.ok(settingsSource.includes('notificationsBodyFont", "notificationsBodyFontSize"'),
  'body font must participate in subtab dirty tracking');
assert.ok(navSource.includes('"notificationsBodyFont", "notificationsBodyFontSize"'),
  'the notification appearance subtab must track the new font field');

// Validate and normalize the font family on profile load.
const liveConfig = {};
apply.apply({}, liveConfig, { notificationsBodyFont: '  Notice\nBody\tFont  ' });
assert.strictEqual(liveConfig.notificationsBodyFont, 'Notice Body Font');
apply.apply({}, liveConfig, { notificationsBodyFont: 'x'.repeat(200) });
assert.strictEqual(liveConfig.notificationsBodyFont.length, 128);
apply.apply({}, liveConfig, { notificationsBodyFont: null });
assert.strictEqual(liveConfig.notificationsBodyFont, '');

// Old full profiles gain the empty inherited default; sparse overrides stay sparse.
const full = schema.normalizeProfile({ notificationsBodyFontSize: 12 }, false);
assert.strictEqual(full.notificationsBodyFont, '');
const sparse = schema.normalizeProfile({ notificationsBodyFontSize: 14 }, true);
assert.ok(!Object.prototype.hasOwnProperty.call(sparse, 'notificationsBodyFont'));
const normalized = schema.normalizeProfile({ notificationsBodyFont: '  Body\nFamily ', notificationsBodyFontSize: 13 }, true);
assert.strictEqual(normalized.notificationsBodyFont, 'Body Family');

// Notification font remains inside Notifications profile scope only.
assert.strictEqual(profiles.modulePathMatches(['notificationsBodyFont'], 'notifications'), true);
assert.strictEqual(profiles.modulePathMatches(['notificationsBodyFont'], 'player'), false);
assert.strictEqual(profiles.profileSavePathMatches({}, 'notifications', null, ['notificationsBodyFont']), true);
assert.strictEqual(profiles.profileSavePathMatches({}, 'general', null, ['notificationsBodyFont']), false);

// Both module reset and page reset restore the active profile value.
const profile = { notificationsBodyFont: 'Profile Notice Font' };
function makeOwner() {
  return {
    activeProfile: 'Default', profiles: { Default: {} },
    expandedProfileData: () => profile,
    geometry: { notifications: [-999999, 16, 380, 0] },
    moduleFrames: { notifications: true }, moduleBackgrounds: { notifications: true },
    moduleBlurEnabled: { notifications: false }, moduleMonitors: {},
    defaultModuleFrames: { notifications: true }, defaultModuleBackgrounds: { notifications: true },
    defaultModuleBlurEnabled: { notifications: false },
    notifications: true, saveCount: 0, save() { this.saveCount += 1; }
  };
}
let owner = makeOwner();
let resetConfig = { notificationsBodyFont: 'Edited Notice Font' };
resets.resetModule(owner, resetConfig, 'notifications');
assert.strictEqual(resetConfig.notificationsBodyFont, profile.notificationsBodyFont);
assert.strictEqual(owner.saveCount, 1);
owner = makeOwner();
resetConfig = { notificationsBodyFont: 'Edited Notice Font' };
resets.resetNotificationsSettings(owner, resetConfig);
assert.strictEqual(resetConfig.notificationsBodyFont, profile.notificationsBodyFont);
assert.strictEqual(owner.saveCount, 1);

assert.ok(checksSource.includes('run_test "$ROOT/tests/test_notifications_body_font_override.sh"'),
  'integration test must be registered in CHECK.sh');
console.log('Notifications body font override: rendering, measuring, inherited default, validation, persistence, search, profile scope and reset: OK');
NODE
