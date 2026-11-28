#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'JS'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const root = process.argv[2];
const read = file => fs.readFileSync(path.join(root, file), 'utf8');
const config = read('Config.qml');
const defaults = read('js/settings/SettingsDefaults.js');
const persistence = read('js/settings/SettingsPersistence.js');
const apply = read('js/settings/SettingsApplyCore.js');
const schema = read('js/settings/SettingsSchema.js');
const resets = read('js/settings/SettingsResets.js');
const section = read('components/settings/sections/SettingsNotificationsSection.qml');
const navigation = read('components/settings/SettingsNavigationController.qml');
const runtime = read('components/notifications/Notifications.qml');

const field = 'notificationsShowAppIconBackground';
assert(config.includes(`property bool ${field}: true`), 'Config defaults app-icon background to the existing appearance');
assert(defaults.includes(`${field}: true`), 'new profiles retain the current app-icon background by default');
assert(persistence.includes(`${field}: config.${field}`), 'settings snapshots persist the toggle');
assert(apply.includes(`o.${field} !== undefined) Config.${field} = !!o.${field}`), 'settings loader restores the toggle');
assert(resets.includes(`"${field}"`), 'module and Notifications page reset lists include the toggle');
assert(navigation.includes(`"${field}"`), 'Appearance subtab dirty tracking includes the toggle');
assert(section.includes('text: "Показывать фон под иконкой приложения"'), 'Settings exposes the app-icon background checkbox');
assert(section.includes(`checked: Config.${field}`) && section.includes(`Config.${field} = checked`), 'checkbox follows and updates Config');
assert(section.includes('enabled: Config.notificationsShowAppIcon'), 'background toggle is disabled when app icons are hidden');
assert(section.includes('settingsSearchId: "notifications-show-app-icon-background"'), 'toggle is indexed by global settings search');
assert(runtime.includes('card.hasAppIcon && !Config.notificationsShowAppIconBackground'), 'transparent background applies only to app icons');
assert(runtime.includes('color: card.hasAppIcon && !Config.notificationsShowAppIconBackground\n                            ? "transparent" : Config.baseColor'), 'app-icon background can be removed without changing avatar/image surfaces');
assert(runtime.includes('id: notificationVisualViewport') && runtime.includes('anchors.fill: parent\n                            clip: true'), 'leading visual has a dedicated clipped viewport');
assert(runtime.includes('sourceSize: Qt.size(Math.max(1, Math.round(width * 2)), Math.max(1, Math.round(height * 2)))'), 'image source size follows the bounded display geometry');
assert(runtime.includes('fillMode: card.hasLeadingImage && root.notificationIsMessenger(card.notification)\n                                    ? Image.PreserveAspectCrop : Image.PreserveAspectFit'), 'icons and non-messenger visuals preserve aspect ratio');
assert(runtime.includes('                                clip: true\n                                smooth: true'), 'image item clips content to its own bounds');

function load(source, expression) {
  const context = {};
  vm.createContext(context);
  vm.runInContext(source.replace(/^\.pragma library\s*$/gm, '').replace(/^\.import .*$/gm, '') + `\nthis.api = { ${expression} };`, context);
  return context.api;
}
const schemaApi = load(schema, 'normalizeProfile');
assert.strictEqual(schemaApi.normalizeProfile({}, false)[field], true, 'legacy full profiles inherit the unchanged visible-background default');
assert.strictEqual(schemaApi.normalizeProfile({ [field]: false }, false)[field], false, 'full profiles preserve the transparent-background choice');
assert.strictEqual(schemaApi.normalizeProfile({ [field]: 'invalid' }, false)[field], true, 'invalid full-profile values fall back safely');
const sparse = schemaApi.normalizeProfile({ [field]: false }, true);
assert.strictEqual(sparse[field], false, 'sparse profiles retain the explicit false override');
assert.strictEqual(Object.prototype.hasOwnProperty.call(schemaApi.normalizeProfile({}, true), field), false, 'sparse profiles do not gain a default override');
assert.strictEqual(Object.prototype.hasOwnProperty.call(schemaApi.normalizeProfile({ [field]: 'invalid' }, true), field), false, 'invalid sparse values are removed so the base profile is inherited');

const resetApi = load(resets, 'resetNotificationsSettings');
const owner = {
  activeProfile: 'Work', profiles: { Work: {} },
  expandedProfileData: () => ({ [field]: false }),
  defaultConfig: {}, geometry: { notifications: [8, 9, 380, 0] }, defaultGeometry: { notifications: [-999999, 16, 380, 0] },
  save() {}, resetUnavailable(message) { throw new Error(message); }
};
const cfg = { [field]: true };
resetApi.resetNotificationsSettings(owner, cfg);
assert.strictEqual(cfg[field], false, 'Notifications reset restores the active profile override');
console.log('notifications app-icon background setting, sparse profiles, reset, persistence, clipped icon viewport: OK');
JS
