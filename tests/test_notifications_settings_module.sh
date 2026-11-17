#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'JS'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const root = process.argv[2];
const read = relative => fs.readFileSync(path.join(root, relative), 'utf8');
const config = read('Config.qml');
const defaults = read('js/settings/SettingsDefaults.js');
const metadata = read('js/settings/SettingsMetadata.js');
const applySource = read('js/settings/SettingsApplyCore.js');
const persistenceSource = read('js/settings/SettingsPersistence.js');
const cliSettings = read('scripts/settings');
const profilesSource = read('js/settings/SettingsProfiles.js');
const resetsSource = read('js/settings/SettingsResets.js');
const settings = read('Settings.qml');
const widget = read('components/settings/SettingsWidget.qml');
const registry = read('js/settings/SettingsPageRegistry.js');
const section = read('components/settings/sections/SettingsNotificationsSection.qml');
const modulesSection = read('components/settings/sections/SettingsModulesSection.qml');
const notifications = read('components/notifications/Notifications.qml');
const geometryHelper = read('js/NotificationsGeometry.js');

const fields = [
  'notificationsDefaultTimeout', 'notificationsCriticalTimeout', 'notificationsCardWidth', 'notificationsCardSpacing',
  'notificationsImageHeight', 'notificationsShowAppIcon', 'notificationsShowBodyImages', 'notificationsShowProgress'
];
for (const field of fields) {
  const type = ['notificationsShowAppIcon','notificationsShowBodyImages','notificationsShowProgress'].includes(field) ? 'bool' : 'int';
  assert(config.includes(`property ${type} ${field}:`), `Config declares ${field}`);
  assert(defaults.includes(`${field}:`), `profile defaults include ${field}`);
  assert(persistenceSource.includes(`${field}: config.${field}`), `snapshot persists ${field}`);
  assert(applySource.includes(`o.${field}`), `settings loader restores ${field}`);
  assert(notifications.includes(`Config.${field}`), `notification runtime consumes ${field}`);
}

assert(!config.includes('property string notificationsPosition:'), 'legacy full-corner property is not an active setting');
assert(config.includes('property string notificationsVerticalAnchor: \"top\"'), 'only top/bottom vertical anchoring is active');
assert(defaults.includes('notificationsVerticalAnchor: \"top\"') && persistenceSource.includes('notificationsVerticalAnchor: config.notificationsVerticalAnchor'), 'vertical anchor is included in defaults and persistence');
assert(applySource.includes('o.notificationsVerticalAnchor') && applySource.includes('legacyPosition.indexOf(\"bottom-\") === 0'), 'new top/bottom mode loads directly and migrates old bottom corners');
assert(!config.includes('property int notificationsOffsetX:') && !config.includes('property int notificationsOffsetY:'), 'active offset properties are removed');
assert(config.includes('notificationsLegacyPosition') && config.includes('notificationsLegacyOffsetX') && config.includes('notificationsLegacyOffsetY'), 'only hidden one-time legacy migration inputs remain');
assert(!defaults.includes('notificationsPosition:') && !defaults.includes('notificationsOffsetX:') && !defaults.includes('notificationsOffsetY:'), 'corner/offset values are no longer defaults');
assert(!persistenceSource.includes('notificationsPosition: config.') && !persistenceSource.includes('notificationsOffsetX: config.') && !persistenceSource.includes('notificationsOffsetY: config.'), 'corner/offset values are absent from active persistence snapshot');
for (const key of ['notificationsPosition', 'notificationsOffsetX', 'notificationsOffsetY', 'notificationsMargin'])
  assert(persistenceSource.includes(`"${key}"`), `${key} is explicitly pruned from old settings files`);

assert(registry.includes('{ id: "notifications", defaultLabel: "Уведомления" }'), 'sidebar declares the Notifications page');
assert(config.includes('"launcher", "notifications", "settingsWindow"') && defaults.includes('"launcher", "notifications", "settingsWindow"'), 'default sidebar order places Notifications before Settings Window');
assert(registry.includes('{ id: "notifications", saveScope: "notifications", subTabs: ["Поведение", "Внешний вид", "Размещение"] }'), 'Notifications page exposes Behavior, Appearance and Placement subtabs');
assert(widget.includes('notifications: "notifications"'), 'sidebar dirty indicator maps the Notifications page to its reset scope');
assert(widget.includes('settings.resetNotificationsSettings()'), 'page reset button invokes the notification reset');
assert(widget.includes('SettingsNotificationsSection {'), 'SettingsWidget instantiates the notification settings section');
assert(section.includes('visible: host && host.currentPageId === "notifications"'), 'section is routed only to the Notifications page');
assert(section.includes('settings.save()'), 'section saves edits immediately');
assert(section.includes('notificationsDefaultTimeout') && section.includes('notificationsCriticalTimeout'), 'section exposes separate normal and critical timeout controls');
assert(!section.includes('notificationsPosition') && !section.includes('notificationsOffsetX') && !section.includes('notificationsOffsetY') && !section.includes('notificationsMargin'), 'legacy placement controls are removed from the Notifications page');
assert(section.includes('currentPageSubTabIndex === 2') && section.includes('Вертикальная привязка') && section.includes('Сверху') && section.includes('Снизу') && section.includes('setNotificationsVerticalAnchor'), 'Notifications page owns a top/bottom-only vertical anchor control');
assert(!section.includes('notificationsCardWidth') && section.includes('notificationsCardSpacing'), 'Notifications page no longer contains the moved window-width control');
assert(modulesSection.includes('moduleRow.moduleName === "notifications"') && modulesSection.includes('modulesSection.writeNotificationsGeometry(index, n)'), 'Modules page exposes notification window width and maximum height through shared geometry fields');
assert(section.includes('notificationsShowAppIcon') && section.includes('notificationsShowBodyImages') && section.includes('notificationsShowProgress'), 'section exposes display toggles');

assert(settings.includes('notifications: [-999999,16,380,0]'), 'Settings singleton has absolute notification X/Y geometry defaults');
assert(metadata.includes('"notifications":[-999999,16,380,0]'), 'profile defaults include notification absolute geometry');
assert(modulesSection.includes('text: settings.moduleLabels[moduleRow.moduleName]') && modulesSection.includes('checked: settings[moduleRow.moduleName]'), 'Modules page exposes Notifications through the common module-enable row');
assert(modulesSection.includes('notificationsGeometryValue(index)') && modulesSection.includes('writeNotificationsGeometry(index, n)'), 'Modules page exposes notification X/Y and size in common geometry fields');
assert(modulesSection.includes('settings.saveProfileScope(settings.activeProfile, "module", moduleRow.moduleName)'), 'notification geometry participates in the standard module profile scope');
assert(!modulesSection.includes('Привязка к углу') && !modulesSection.includes('Отступ по горизонтали') && !modulesSection.includes('notificationsPositionCombo'), 'corner and edge-margin controls are completely removed');
assert(modulesSection.includes('settings.saveProfileScope(settings.activeProfile, "module", moduleRow.moduleName)'), 'notification module uses the generic scoped profile saving action');
assert(modulesSection.includes('settings.resetModule(moduleRow.moduleName)'), 'notification module uses the generic scoped reset action');
assert(modulesSection.includes('text: "Фон"') && modulesSection.includes('text: "Рамка"') && modulesSection.includes('text: "Блюр"'), 'notification module exposes independent background, frame and blur checkboxes');
assert(modulesSection.includes('settings.moduleBackgrounds[moduleRow.moduleName] !== false') && modulesSection.includes('settings.moduleFrames[moduleRow.moduleName] !== false'), 'background and frame toggles use common enabled-by-default semantics');
assert(modulesSection.includes('settings.setModuleBlurEnabled(moduleRow.moduleName, checked)'), 'blur toggle uses the shared per-module blur setter');
assert(modulesSection.includes('settings.moduleFrames[moduleRow.moduleName]') && modulesSection.includes('settings.moduleBackgrounds[moduleRow.moduleName]') && modulesSection.includes('settings.moduleBlurEnabled[moduleRow.moduleName]'), 'appearance options use the common module control maps');
assert(notifications.includes('Settings.moduleBackgrounds.notifications !== false ? Config.background : Config.transparent'), 'background checkbox changes card fill without affecting the frame');
assert(notifications.includes('Settings.moduleFrames.notifications !== false ? Math.max(1, Config.frameBorderWidth) : 0'), 'frame checkbox independently controls card border');
assert(notifications.includes('Settings.moduleBlurEnabled.notifications === true') && notifications.includes('? (notificationServer.trackedNotifications.values.length > 0 ? notificationList : layoutEditPreview)'), 'blur checkbox controls compositor blur behind the queue or its smart-edit preview');
assert(cliSettings.includes('"notifications":true'), 'CLI settings defaults also enable the Notifications module');
assert(notifications.includes('Settings.geometry') && notifications.includes('margins.left: root.notificationCoordinate(0)') && notifications.includes('margins.bottom:'), 'toast window uses module X and a top/bottom vertical inset');
assert(notifications.includes('anchors.left: true') && notifications.includes('anchors.top: String(Config.notificationsVerticalAnchor || \"top\") !== \"bottom\"') && notifications.includes('anchors.bottom: String(Config.notificationsVerticalAnchor || \"top\") === \"bottom\"'), 'toast window can anchor to the selected screen top or bottom while remaining left-anchored');
const popupWindowBlock = notifications.slice(notifications.indexOf('PanelWindow {\n        id: popupWindow'), notifications.indexOf('Item {\n            id: notificationContent'));
assert(!popupWindowBlock.includes('anchors.right:') && popupWindowBlock.includes('anchors.bottom:') && !notifications.includes('Config.notificationsPosition') && !notifications.includes('Config.notificationsOffsetX') && !notifications.includes('Config.notificationsOffsetY'), 'runtime supports only vertical top/bottom anchoring, not horizontal corner anchoring');
assert(notifications.includes('notificationTargetScreen()'), 'notification window resolves its target monitor like other modules');
assert(notifications.includes('migrateLegacyNotificationCoordinates'), 'old corner settings are converted once to absolute coordinates');
assert(shellHasNotificationLoader(read('shell.qml')), 'notification server loader follows module enable after settings load');
assert(read('shell.qml').includes('NotificationComponents.Notifications {}'), 'loader constructs the native notification component');
assert(!widget.includes('notificationsMargin'), 'legacy margin is absent from Notifications Appearance dirty tracking');
assert(section.includes('onNotificationsShowAppIconChanged()') && section.includes('onNotificationsShowBodyImagesChanged()') && section.includes('onNotificationsShowProgressChanged()'), 'display toggles stay synchronized when settings profiles switch');
assert(settings.includes('function resetNotificationsSettings()'), 'Settings object exposes notification reset adapter');
assert(settings.includes('notifications: ["notifications"]'), 'reset visibility includes notification scope');
assert(resetsSource.includes('function resetNotificationsSettings(owner, config)') && resetsSource.includes('\"notificationsVerticalAnchor\"'), 'profile reset implementation includes the vertical anchor');
assert(!resetsSource.includes('geometry.notifications = profile.geometry && profile.geometry.notifications'), 'Notifications content reset no longer resets module geometry');
assert(profilesSource.includes('notifications: ["notifications"]'), 'save-profile scope includes notification preferences');
assert(widget.includes('notificationsDefaultTimeout", "notificationsCriticalTimeout'), 'Behavior subtab has focused dirty tracking');
assert(widget.includes('keys: ["notificationsCardSpacing", "notificationsImageHeight", "notificationsShowAppIcon", "notificationsShowBodyImages", "notificationsShowProgress"]'), 'Appearance subtab tracks only the remaining notification-content fields');
assert(section.includes('changeKeys: ({ keys: [\"notificationsVerticalAnchor\"] })'), 'Placement subtab tracks its own vertical anchor field');

function shellHasNotificationLoader(source) {
  return source.includes('active: Settings.loaded && Settings.notifications');
}
function load(relative, exportLine) {
  const source = read(relative).replace(/^\.pragma library\s*$/gm, '').replace(/^\.import .*$/gm, '');
  const context = {};
  vm.runInNewContext(source + `\nthis.api = { ${exportLine} };`, context, { filename: relative });
  return context.api;
}

// Execute the real SettingsApplyCore loader and validate normal fields plus legacy inputs.
const apply = load('js/settings/SettingsApplyCore.js', 'apply, normalizeSettingsTabOrder');
const loaded = {};
apply.apply({}, loaded, {
  notificationsDefaultTimeout: 135000,
  notificationsCriticalTimeout: -50,
  notificationsPosition: 'bottom-left',
  notificationsOffsetX: 22,
  notificationsOffsetY: 24,
  notificationsMargin: 999,
  notificationsCardWidth: 210,
  notificationsCardSpacing: 40,
  notificationsImageHeight: 400,
  notificationsShowAppIcon: 0,
  notificationsShowBodyImages: 1,
  notificationsShowProgress: false
});
assert.strictEqual(loaded.notificationsDefaultTimeout, 120000, 'normal timeout is clamped to 120s');
assert.strictEqual(loaded.notificationsCriticalTimeout, 0, 'critical timeout is clamped to non-negative');
assert.strictEqual(loaded.notificationsLegacyPosition, 'bottom-left', 'old corner is retained only as a migration input');
assert.strictEqual(loaded.notificationsVerticalAnchor, 'bottom', 'old bottom-left corner maps to the new bottom-only anchor');
assert.strictEqual(loaded.notificationsLegacyOffsetX, 22, 'old X offset is retained only for one-time migration');
assert.strictEqual(loaded.notificationsLegacyOffsetY, 24, 'old Y offset is retained only for one-time migration');
assert.strictEqual(loaded.notificationsCardWidth, 280, 'card width is clamped');
assert.strictEqual(loaded.notificationsCardSpacing, 32, 'queue spacing is clamped');
assert.strictEqual(loaded.notificationsImageHeight, 320, 'preview height is clamped');
assert.strictEqual(loaded.notificationsShowAppIcon, false, 'app-icon toggle is restored');
assert.strictEqual(loaded.notificationsShowBodyImages, true, 'body-image toggle is restored');
assert.strictEqual(loaded.notificationsShowProgress, false, 'progress toggle is restored');
const marginOnly = {};
apply.apply({}, marginOnly, { notificationsMargin: 90 });
assert.strictEqual(marginOnly.notificationsLegacyOffsetX, 90, 'old symmetric margin migrates to legacy X input');
assert.strictEqual(marginOnly.notificationsLegacyOffsetY, 90, 'old symmetric margin migrates to legacy Y input');
assert.strictEqual(marginOnly.notificationsLegacyPosition, 'top-right', 'old margin-only layout defaults to its former top-right anchor before coordinate conversion');

const persistence = load('js/settings/SettingsPersistence.js', 'snapshotObject');
const snapshotConfig = Object.fromEntries(fields.map((field, i) => [field, [6000, 1000, 420, 12, 150, false, true, false][i]]));
snapshotConfig.notificationsVerticalAnchor = 'bottom';
const snapshot = persistence.snapshotObject({ weatherToken: '', moduleNames: ['notifications'], colorNames: [], notifications: false, geometry: { notifications: [123, 456, 380, 0] } }, snapshotConfig);
for (const field of fields) assert.strictEqual(snapshot[field], snapshotConfig[field], `snapshot retains ${field}`);
assert.deepStrictEqual(Array.from(snapshot.geometry.notifications), [123, 456, 380, 0], 'snapshot persists notification X/Y through standard module geometry');
assert.strictEqual(snapshot.modules.notifications, false, 'snapshot persists the Notifications module enable flag');
assert.strictEqual(snapshot.notificationsVerticalAnchor, 'bottom', 'snapshot persists the selected vertical anchor');
assert(!Object.prototype.hasOwnProperty.call(snapshot, 'notificationsPosition'), 'snapshot does not persist old corner mode');

const profiles = load('js/settings/SettingsProfiles.js', 'profileSavePathMatches');
assert.strictEqual(profiles.profileSavePathMatches({}, 'notifications', null, ['notificationsCardWidth']), false, 'Notifications page scope excludes the moved module width');
assert.strictEqual(profiles.profileSavePathMatches({}, 'modules', null, ['notificationsCardWidth']), true, 'Modules scope includes the moved notification width');
assert.strictEqual(profiles.profileSavePathMatches({}, 'notifications', null, ['launcherWidth']), false, 'notification save scope excludes launcher preferences');
assert.strictEqual(profiles.profileSavePathMatches({}, 'module', 'notifications', ['modules', 'notifications']), true, 'module scope includes notification enable flag');
assert.strictEqual(profiles.profileSavePathMatches({}, 'module', 'notifications', ['geometry', 'notifications']), true, 'module scope includes notification geometry');

const resets = load('js/settings/SettingsResets.js', 'resetNotificationsSettings, resetModule');
const profileSettings = Object.fromEntries(fields.map((field, i) => [field, [9000, 2000, 440, 14, 160, false, false, false][i]]));
profileSettings.notificationsVerticalAnchor = 'bottom';
const resetConfig = Object.fromEntries(fields.map(field => [field, 'changed']));
resetConfig.notificationsVerticalAnchor = 'top';
let saveCount = 0;
const resetOwner = {
  activeProfile: 'Work', profiles: { Work: {} },
  expandedProfileData: () => ({ ...profileSettings, geometry: { notifications: [41, 52, 440, 0] } }),
  geometry: { notifications: [8, 9, 380, 0] }, defaultGeometry: { notifications: [-999999, 16, 380, 0] },
  save: () => { saveCount += 1; },
  resetUnavailable: message => { throw new Error(message); }
};
resets.resetNotificationsSettings(resetOwner, resetConfig);
for (const field of fields.filter(field => field !== 'notificationsCardWidth')) assert.strictEqual(resetConfig[field], profileSettings[field], `reset restores ${field} from the active profile`);
assert.strictEqual(resetConfig.notificationsCardWidth, 'changed', 'Notifications content reset leaves the module width untouched');
assert.strictEqual(resetConfig.notificationsVerticalAnchor, 'bottom', 'Notifications page reset restores vertical anchoring');
assert.deepStrictEqual(Array.from(resetOwner.geometry.notifications), [8, 9, 380, 0], 'notification page reset leaves module geometry untouched');
assert.strictEqual(saveCount, 1, 'reset persists the restored notification settings once');

const moduleProfile = { modules: { notifications: false }, notificationsCardWidth: 460, notificationsVerticalAnchor: 'bottom', geometry: { notifications: [71, 82, 440, 320] } };
const moduleOwner = {
  activeProfile: 'Work', profiles: { Work: {} }, expandedProfileData: () => moduleProfile,
  notifications: true, geometry: {}, defaultGeometry: { notifications: [-999999, 16, 380, 0] },
  moduleFrames: {}, moduleBackgrounds: {}, moduleBlurEnabled: {}, moduleMonitors: {}, defaultModuleBlurEnabled: {}, save: () => { saveCount += 1; }
};
const moduleConfig = { notificationsCardWidth: 380, notificationsVerticalAnchor: 'top' };
resets.resetModule(moduleOwner, moduleConfig, 'notifications');
assert.strictEqual(moduleOwner.notifications, false, 'module reset restores Notifications enabled/disabled state');
assert.deepStrictEqual(Array.from(moduleOwner.geometry.notifications), [71, 82, 460, 320], 'module reset restores notification X/Y and dimensions');
assert.strictEqual(moduleConfig.notificationsCardWidth, 460, 'module reset keeps legacy width synchronized');
assert.strictEqual(moduleConfig.notificationsVerticalAnchor, 'bottom', 'module reset restores the selected vertical anchor');

const geometry = load('js/NotificationsGeometry.js', 'resolvedCoordinate, migrateLegacyPlacement, normalizeGeometry');
assert.strictEqual(geometry.resolvedCoordinate([-999999, 16, 380, 0], 0, 1920, 380, 16), 1524, 'auto default X preserves previous top-right default as a numeric coordinate');
assert.strictEqual(geometry.resolvedCoordinate([123, 456, 380, 0], 0, 1920, 380, 16), 123, 'explicit X remains an absolute coordinate');
assert.strictEqual(geometry.resolvedCoordinate([123, 456, 380, 0], 1, 1920, 380, 16), 456, 'explicit Y remains an absolute coordinate');
assert.deepStrictEqual(Array.from(geometry.migrateLegacyPlacement('bottom-left', 41, 27, 1920, 1080, 380, 180)), [41, 873, 380, 0], 'legacy bottom-left is converted once into absolute X/Y');
assert.deepStrictEqual(Array.from(geometry.normalizeGeometry([12, 24, 400, 200], 380)), [12, 24, 380, 200], 'normalization preserves optional maximum height alongside absolute position');

console.log('Notifications absolute X/Y geometry, one-time legacy migration, persistence, profile scope and reset: OK');
JS
