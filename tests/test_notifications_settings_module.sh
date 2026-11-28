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
const navigation = read('components/settings/SettingsNavigationController.qml');
const pageContent = read('components/settings/SettingsPageContent.qml');
const registry = read('js/settings/SettingsPageRegistry.js');
const section = read('components/settings/sections/SettingsNotificationsSection.qml');
const modulesSection = read('components/settings/sections/SettingsModulesSection.qml');
const notifications = read('components/notifications/Notifications.qml');
const geometryHelper = read('js/NotificationsGeometry.js');

const fields = [
  'notificationsDefaultTimeout', 'notificationsCriticalTimeout', 'notificationsCardWidth', 'notificationsCardSpacing',
  'notificationsImageHeight', 'notificationsBackgroundColor', 'notificationsSummaryFont', 'notificationsSummaryFontSize',
  'notificationsSummaryColor', 'notificationsAppNameFont', 'notificationsAppNameFontSize', 'notificationsAppNameColor',
  'notificationsAppNameBold', 'notificationsLeadingVisualSize', 'notificationsLeadingVisualRadius', 'notificationsCardPadding',
  'notificationsBodyFont', 'notificationsBodyFontSize', 'notificationsBodyColor', 'notificationsTimeoutIndicatorColor', 'notificationsTimeoutIndicatorStyle', 'notificationsTimeoutIndicatorDirection', 'notificationsShowAppIcon', 'notificationsShowAppIconBackground', 'notificationsShowBodyImages', 'notificationsShowProgress'
];
const boolFields = ['notificationsAppNameBold','notificationsShowAppIcon','notificationsShowAppIconBackground','notificationsShowBodyImages','notificationsShowProgress'];
const colorFields = ['notificationsBackgroundColor'];
const stringFields = ['notificationsSummaryFont','notificationsSummaryColor','notificationsAppNameFont','notificationsAppNameColor','notificationsBodyFont','notificationsBodyColor','notificationsTimeoutIndicatorColor','notificationsTimeoutIndicatorStyle','notificationsTimeoutIndicatorDirection'];
for (const field of fields) {
  const type = boolFields.includes(field) ? 'bool' : (colorFields.includes(field) ? 'color' : (stringFields.includes(field) ? 'string' : 'int'));
  assert(config.includes(`property ${type} ${field}:`), `Config declares ${field}`);
  assert(defaults.includes(`${field}:`), `profile defaults include ${field}`);
  const snapshotField = colorFields.includes(field) || ['notificationsSummaryColor','notificationsAppNameColor','notificationsBodyColor'].includes(field) ? `${field}: String(config.${field})` : `${field}: config.${field}`;
  assert(persistenceSource.includes(snapshotField), `snapshot persists ${field}`);
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

assert(registry.includes('{ id: "notifications", defaultLabel: "Уведомления", groupId: "notifications", description:'), 'sidebar declares the Notifications page in its own folder');
assert(registry.includes('{ id: "notificationsDnd", defaultLabel: "Правила и история", groupId: "notifications", description:'), 'sidebar declares DND rules/history as a separate Notifications page');
assert(registry.includes('subTabs: ["Приложения", "История"]'), 'DND page contains only app rules and history subtabs');
assert(config.includes('property var settingsNavigationOrder:'), 'Config declares the canonical hierarchical navigation order');
assert(defaults.includes('settingsNavigationOrder: ({'), 'profile defaults use the canonical hierarchical navigation order');
assert(!config.includes('property var settingsTabOrder:'), 'Config no longer creates the obsolete flat runtime order');
assert(!defaults.includes('settingsTabOrder:'), 'new profiles no longer receive the obsolete flat order');
const navigationRegistry = {};
vm.runInNewContext(registry.replace(/^\.pragma library\s*$/gm, '').replace(/^\.import .*$/gm, ''), navigationRegistry);
assert.strictEqual(navigationRegistry.navigationGroupIdForTabId('notifications'), 'notifications', 'Notifications belongs to its own folder');
assert.strictEqual(navigationRegistry.navigationGroupIdForTabId('notificationsDnd'), 'notifications', 'DND belongs to the Notifications folder');
assert.strictEqual(navigationRegistry.navigationGroupIdForTabId('settingsWindow'), 'appearance', 'Settings Window belongs to Appearance rather than a global flat order');
const defaultNavigation = navigationRegistry.defaultNavigationOrder();
assert(defaultNavigation.pagesByGroup.notifications.includes('notifications'), 'Notifications is available in its dedicated folder');
assert(defaultNavigation.pagesByGroup.notifications.includes('notificationsDnd'), 'DND is a separate page in the Notifications folder');
assert(registry.includes('{ id: "notifications", saveScope: "notifications", subTabs: ["Поведение", "Внешний вид", "Размещение", "Анимация"] }'), 'Notifications page exposes Behavior, Appearance and Placement subtabs');
assert(navigation.includes('notifications: "notifications"') && navigation.includes('notificationsDnd: "notifications"'), 'sidebar dirty indicators map both notification pages to the shared reset scope');
assert(navigation.includes('settings.resetNotificationsSettings()'), 'page reset button invokes the notification reset');
assert(navigation.includes('pageId === "notifications" || pageId === "notificationsDnd"'), 'notification sidebar dirty markers aggregate their own subtabs independently');
assert(pageContent.includes('SettingsNotificationsSection {'), 'SettingsPageContent instantiates the notification settings section');
assert(section.includes('pageId === "notificationsDnd"'), 'section also renders the dedicated DND page');
assert(section.includes('settings.save()'), 'section saves edits immediately');
assert(section.includes('notificationsDefaultTimeout') && section.includes('notificationsCriticalTimeout'), 'section exposes separate normal and critical timeout controls');
assert(!section.includes('notificationsPosition') && !section.includes('notificationsOffsetX') && !section.includes('notificationsOffsetY') && !section.includes('notificationsMargin'), 'legacy placement controls are removed from the Notifications page');
assert(section.includes('currentPageSubTabIndex === 2') && section.includes('Вертикальная привязка') && section.includes('Сверху') && section.includes('Снизу') && section.includes('setNotificationsVerticalAnchor'), 'Notifications page owns a top/bottom-only vertical anchor control');
assert(!section.includes('notificationsCardWidth') && section.includes('notificationsCardSpacing'), 'Notifications page no longer contains the moved window-width control');
assert(modulesSection.includes('moduleRow.moduleName === "notifications"') && modulesSection.includes('modulesSection.writeNotificationsGeometry(index, n)'), 'Modules page exposes notification window width and maximum height through shared geometry fields');
assert(section.includes('notificationsShowAppIcon') && section.includes('notificationsShowAppIconBackground') && section.includes('notificationsShowBodyImages') && section.includes('notificationsShowProgress'), 'section exposes display toggles including app-icon background');
assert(section.includes('heading: "Фон уведомлений"') && section.includes('targetProperty: "notificationsBackgroundColor"'), 'Notifications exposes an independent background color control');

assert(settings.includes('notifications: [-999999,16,380,0]'), 'Settings singleton has absolute notification X/Y geometry defaults');
assert(metadata.includes('"notifications":[-999999,16,380,0]'), 'profile defaults include notification absolute geometry');
assert(modulesSection.includes('text: settings.moduleLabels[moduleRow.moduleName]') && modulesSection.includes('checked: settings[moduleRow.moduleName]'), 'Modules page exposes Notifications through the common module-enable row');
assert(modulesSection.includes('notificationsGeometryValue(index)') && modulesSection.includes('writeNotificationsGeometry(index, n)'), 'Modules page exposes notification X/Y and size in common geometry fields');
assert(modulesSection.includes('host.profileController.saveScope(moduleRow.moduleName === "dashboard" ? "dashboardModule" : "module", moduleRow.moduleName)'), 'notification geometry participates in the standard module profile scope');
assert(!modulesSection.includes('Привязка к углу') && !modulesSection.includes('Отступ по горизонтали') && !modulesSection.includes('notificationsPositionCombo'), 'corner and edge-margin controls are completely removed');
assert(modulesSection.includes('host.profileController.saveScope(moduleRow.moduleName === "dashboard" ? "dashboardModule" : "module", moduleRow.moduleName)'), 'notification module uses the generic scoped profile saving action');
assert(modulesSection.includes('settings.resetModule(moduleRow.moduleName)'), 'notification module uses the generic scoped reset action');
assert(modulesSection.includes('text: "Фон"') && modulesSection.includes('text: "Рамка"') && modulesSection.includes('text: "Блюр"'), 'notification module exposes independent background, frame and blur checkboxes');
assert(modulesSection.includes('settings.moduleBackgrounds[moduleRow.moduleName] !== false') && modulesSection.includes('settings.moduleFrames[moduleRow.moduleName] !== false'), 'background and frame toggles use common enabled-by-default semantics');
assert(modulesSection.includes('settings.setModuleBlurEnabled(moduleRow.moduleName, checked)'), 'blur toggle uses the shared per-module blur setter');
assert(modulesSection.includes('settings.moduleFrames[moduleRow.moduleName]') && modulesSection.includes('settings.moduleBackgrounds[moduleRow.moduleName]') && modulesSection.includes('settings.moduleBlurEnabled[moduleRow.moduleName]'), 'appearance options use the common module control maps');
assert(notifications.includes('Settings.moduleBackgrounds.notifications !== false ? Config.background : Config.transparent'), 'background checkbox changes card fill without affecting the frame');
assert(notifications.includes('readonly property int notificationFrameBorderWidth: Settings.moduleFrames.notifications !== false && Config.cardBordersEnabled') && notifications.includes('? Math.max(1, Math.round(Config.frameBorderWidth * notificationUiScale)) : 0') && (notifications.match(/border\.width: root\.notificationFrameBorderWidth/g) || []).length === 2, 'module frame toggle and global border setting consistently control both notification cards and the smart-edit preview');
assert(notifications.includes('Settings.moduleBlurEnabled.notifications === true') && notifications.includes('root.layoutEditMode ? layoutEditPreview : null') && notifications.includes('? notificationList'), 'blur checkbox controls only the active queue or explicit smart-edit preview, and clears while idle');
assert(cliSettings.includes('"notifications":true'), 'CLI settings defaults also enable the Notifications module');
assert(notifications.includes('Settings.geometry') && notifications.includes('margins.left: root.notificationCoordinate(0)') && notifications.includes('margins.bottom:'), 'toast window uses module X and a top/bottom vertical inset');
assert(notifications.includes('anchors.left: true') && notifications.includes('anchors.top: String(Config.notificationsVerticalAnchor || \"top\") !== \"bottom\"') && notifications.includes('anchors.bottom: String(Config.notificationsVerticalAnchor || \"top\") === \"bottom\"'), 'toast window can anchor to the selected screen top or bottom while remaining left-anchored');
const popupWindowBlock = notifications.slice(notifications.indexOf('PanelWindow {\n        id: popupWindow'), notifications.indexOf('Item {\n            id: notificationContent'));
assert(!popupWindowBlock.includes('anchors.right:') && popupWindowBlock.includes('anchors.bottom:') && !notifications.includes('Config.notificationsPosition') && !notifications.includes('Config.notificationsOffsetX') && !notifications.includes('Config.notificationsOffsetY'), 'runtime supports only vertical top/bottom anchoring, not horizontal corner anchoring');
assert(notifications.includes('notificationTargetScreen()'), 'notification window resolves its target monitor like other modules');
assert(notifications.includes('migrateLegacyNotificationCoordinates'), 'old corner settings are converted once to absolute coordinates');
assert(shellHasNotificationLoader(read('shell.qml')), 'notification server bridge remains loaded after settings initialize because the D-Bus owner is process-wide');
assert(notifications.includes('notificationsModuleEnabled: Settings.notifications === true') && notifications.includes('root.dismissTrackedNotifications()'), 'module toggle gates notifications inside the component and dismisses existing cards');
assert(read('shell.qml').includes('NotificationComponents.Notifications {}'), 'loader constructs the native notification component');
assert(!widget.includes('notificationsMargin'), 'legacy margin is absent from Notifications Appearance dirty tracking');
assert(section.includes('onNotificationsShowAppIconChanged()') && section.includes('onNotificationsShowBodyImagesChanged()') && section.includes('onNotificationsShowProgressChanged()'), 'display toggles stay synchronized when settings profiles switch');
assert(settings.includes('function resetNotificationsSettings()'), 'Settings object exposes notification reset adapter');
assert(settings.includes('notifications: ["notifications", "animationNotifications"]'), 'reset visibility includes notification scope');
assert(resetsSource.includes('function resetNotificationsSettings(owner, config)') && resetsSource.includes('\"notificationsVerticalAnchor\"'), 'profile reset implementation includes the vertical anchor');
assert(!resetsSource.includes('geometry.notifications = profile.geometry && profile.geometry.notifications'), 'Notifications content reset no longer resets module geometry');
assert(profilesSource.includes('notifications: ["notifications", "animationNotifications"]'), 'save-profile scope includes notification preferences');
assert(navigation.includes('keys: ["notificationsDoNotDisturb", "notificationsDefaultTimeout", "notificationsCriticalTimeout"'), 'Behavior subtab tracks DND and notification behavior settings');
assert(navigation.includes('keys: ["notificationsCardSpacing", "notificationsImageHeight", "notificationsBackgroundColor", "notificationsSummaryFont", "notificationsSummaryFontSize", "notificationsSummaryColor", "notificationsAppNameFont", "notificationsAppNameFontSize", "notificationsAppNameColor", "notificationsAppNameBold", "notificationsLeadingVisualSize", "notificationsLeadingVisualRadius", "notificationsCardPadding", "notificationsBodyFont", "notificationsBodyFontSize", "notificationsBodyColor", "notificationsShowAppIcon", "notificationsShowAppIconBackground", "notificationsShowBodyImages", "notificationsShowProgress"]'), 'Appearance subtab tracks all notification typography and card appearance settings');
assert(section.includes('heading: "Заголовок и иконка"') && section.includes('targetProperty: "notificationsSummaryFont"') && section.includes('targetProperty: "notificationsSummaryFontSize"') && section.includes('targetProperty: "notificationsSummaryColor"') && section.includes('targetProperty: "notificationsLeadingVisualSize"'), 'Appearance exposes title typography and icon sizing controls');
assert(section.includes('changeKeys: ({ keys: [\"notificationsVerticalAnchor\"] })'), 'Placement subtab tracks its own vertical anchor field');

function shellHasNotificationLoader(source) {
  return /Loader\s*\{\s*id: notificationsModuleLoader\s*active: Settings\.loaded/.test(source)
    && source.includes('process-wide C++ singleton');
}
function load(relative, exportLine) {
  const source = read(relative).replace(/^\.pragma library\s*$/gm, '').replace(/^\.import .*$/gm, '');
  const context = relative === 'js/settings/SettingsApplyCore.js' ? { Schema: { normalizeSavedColor: (value, fallback) => /^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(String(value || '')) ? String(value).toLowerCase() : fallback } } : {};
  vm.runInNewContext(source + `\nthis.api = { ${exportLine} };`, context, { filename: relative });
  return context.api;
}

// Execute the real SettingsApplyCore loader and validate normal fields plus legacy inputs.
const apply = load('js/settings/SettingsApplyCore.js', 'apply');
const loaded = {};
apply.apply({}, loaded, {
  notificationsSummaryFont: '  JetBrains Mono\n',
  notificationsSummaryFontSize: 99,
  notificationsSummaryColor: '#7f12ab34',
  notificationsAppNameFont: '  JetBrains Mono\n', notificationsAppNameFontSize: 1, notificationsAppNameColor: '#AABBCCDD', notificationsAppNameBold: 1,
  notificationsLeadingVisualSize: 100, notificationsLeadingVisualRadius: 99, notificationsCardPadding: -5,
  notificationsBodyFont: '  Notice\nBody Font  ', notificationsBodyFontSize: 99, notificationsBodyColor: '#DDEEFF',
  notificationsDefaultTimeout: 135000,
  notificationsCriticalTimeout: -50,
  notificationsPosition: 'bottom-left',
  notificationsOffsetX: 22,
  notificationsOffsetY: 24,
  notificationsMargin: 999,
  notificationsCardWidth: 210,
  notificationsCardSpacing: 40,
  notificationsImageHeight: 400,
  notificationsBackgroundColor: '#7f182838',
  notificationsShowAppIcon: 0,
  notificationsShowAppIconBackground: 0,
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
assert.strictEqual(loaded.notificationsBackgroundColor, '#7f182838', 'independent notification background color is restored');
assert.strictEqual(loaded.notificationsSummaryFont, 'JetBrains Mono', 'summary font is normalized and restored');
assert.strictEqual(loaded.notificationsSummaryFontSize, 32, 'summary font size is clamped');
assert.strictEqual(loaded.notificationsSummaryColor, '#7f12ab34', 'summary color is normalized and restored');
assert.strictEqual(loaded.notificationsAppNameFont, 'JetBrains Mono', 'application-name font is normalized and restored');
assert.strictEqual(loaded.notificationsAppNameFontSize, 8, 'application-name font size is clamped');
assert.strictEqual(loaded.notificationsAppNameColor, '#aabbccdd', 'application-name color is normalized and restored');
assert.strictEqual(loaded.notificationsAppNameBold, true, 'application-name bold style is restored');
assert.strictEqual(loaded.notificationsLeadingVisualSize, 72, 'leading visual size is clamped');
assert.strictEqual(loaded.notificationsLeadingVisualRadius, 36, 'leading visual radius is clamped');
assert.strictEqual(loaded.notificationsCardPadding, 0, 'card padding is clamped');
assert.strictEqual(loaded.notificationsBodyFont, 'Notice Body Font', 'body font family is normalized and restored');
assert.strictEqual(loaded.notificationsBodyFontSize, 32, 'body font size is clamped');
assert.strictEqual(loaded.notificationsBodyColor, '#ddeeff', 'body color is normalized and restored');
assert.strictEqual(loaded.notificationsShowAppIcon, false, 'app-icon toggle is restored');
assert.strictEqual(loaded.notificationsShowAppIconBackground, false, 'app-icon background toggle is restored');
assert.strictEqual(loaded.notificationsShowBodyImages, true, 'body-image toggle is restored');
assert.strictEqual(loaded.notificationsShowProgress, false, 'progress toggle is restored');
const marginOnly = {};
apply.apply({}, marginOnly, { notificationsMargin: 90 });
assert.strictEqual(marginOnly.notificationsLegacyOffsetX, 90, 'old symmetric margin migrates to legacy X input');
assert.strictEqual(marginOnly.notificationsLegacyOffsetY, 90, 'old symmetric margin migrates to legacy Y input');
assert.strictEqual(marginOnly.notificationsLegacyPosition, 'top-right', 'old margin-only layout defaults to its former top-right anchor before coordinate conversion');

const persistence = load('js/settings/SettingsPersistence.js', 'snapshotObject');
const snapshotValues = {
  notificationsDefaultTimeout: 6000, notificationsCriticalTimeout: 1000, notificationsCardWidth: 420,
  notificationsCardSpacing: 12, notificationsImageHeight: 150, notificationsBackgroundColor: '#7f182838',
  notificationsSummaryFont: 'Inter', notificationsSummaryFontSize: 16, notificationsSummaryColor: '#7f12ab34',
  notificationsAppNameFont: 'Noto Sans', notificationsAppNameFontSize: 13, notificationsAppNameColor: '#ffaa2211', notificationsAppNameBold: true,
  notificationsLeadingVisualSize: 56, notificationsLeadingVisualRadius: 14, notificationsCardPadding: 16,
  notificationsBodyFont: 'Noto Sans', notificationsBodyFontSize: 15, notificationsBodyColor: '#ff112233', notificationsShowAppIcon: false, notificationsShowAppIconBackground: false, notificationsShowBodyImages: true,
  notificationsAppNameFont: 'Noto Sans', notificationsAppNameFontSize: 13, notificationsAppNameColor: '#ffaa2211', notificationsAppNameBold: true,
  notificationsLeadingVisualRadius: 14, notificationsCardPadding: 16, notificationsBodyFontSize: 15, notificationsBodyColor: '#ff112233',
  notificationsShowProgress: false
};
const snapshotConfig = Object.assign({}, snapshotValues);
snapshotConfig.notificationsVerticalAnchor = 'bottom';
const snapshot = persistence.snapshotObject({ weatherToken: '', moduleNames: ['notifications'], colorNames: [], notifications: false, geometry: { notifications: [123, 456, 380, 0] } }, snapshotConfig);
for (const field of fields) assert.strictEqual(snapshot[field], snapshotConfig[field], `snapshot retains ${field}`);
assert.deepStrictEqual(Array.from(snapshot.geometry.notifications), [123, 456, 380, 0], 'snapshot persists notification X/Y through standard module geometry');
assert.strictEqual(snapshot.modules.notifications, false, 'snapshot persists the Notifications module enable flag');
assert.strictEqual(snapshot.notificationsVerticalAnchor, 'bottom', 'snapshot persists the selected vertical anchor');
assert(!Object.prototype.hasOwnProperty.call(snapshot, 'notificationsPosition'), 'snapshot does not persist old corner mode');

const profiles = load('js/settings/SettingsProfiles.js', 'profileSavePathMatches');
assert.strictEqual(profiles.profileSavePathMatches({}, 'notifications', null, ['notificationsCardWidth']), false, 'Notifications page scope excludes the moved module width');
assert.strictEqual(profiles.profileSavePathMatches({}, 'notifications', null, ['notificationsBackgroundColor']), true, 'Notifications page scope includes its independent background color');
assert.strictEqual(profiles.profileSavePathMatches({}, 'notifications', null, ['notificationsShowAppIconBackground']), true, 'Notifications page scope includes the app-icon background toggle');
assert.strictEqual(profiles.profileSavePathMatches({}, 'module', 'notifications', ['notificationsShowAppIconBackground']), true, 'Notifications module scope includes the app-icon background toggle');
for (const field of ['notificationsAppNameFont', 'notificationsAppNameFontSize', 'notificationsAppNameColor', 'notificationsAppNameBold', 'notificationsLeadingVisualRadius', 'notificationsCardPadding', 'notificationsBodyFont', 'notificationsBodyFontSize', 'notificationsBodyColor'])
  assert.strictEqual(profiles.profileSavePathMatches({}, 'notifications', null, [field]), true, `Notifications page scope includes ${field}`);
for (const field of ['notificationsAppNameFont', 'notificationsAppNameFontSize', 'notificationsAppNameColor', 'notificationsAppNameBold', 'notificationsLeadingVisualRadius', 'notificationsCardPadding', 'notificationsBodyFont', 'notificationsBodyFontSize', 'notificationsBodyColor'])
  assert.strictEqual(profiles.profileSavePathMatches({}, 'module', 'notifications', [field]), true, `Notifications module scope includes ${field}`);
assert.strictEqual(profiles.profileSavePathMatches({}, 'module', 'notifications', ['notificationsBackgroundColor']), true, 'Notifications module scope includes its independent background color');
assert.strictEqual(profiles.profileSavePathMatches({}, 'modules', null, ['notificationsCardWidth']), true, 'Modules scope includes the moved notification width');
assert.strictEqual(profiles.profileSavePathMatches({}, 'notifications', null, ['launcherWidth']), false, 'notification save scope excludes launcher preferences');
assert.strictEqual(profiles.profileSavePathMatches({}, 'module', 'notifications', ['modules', 'notifications']), true, 'module scope includes notification enable flag');
assert.strictEqual(profiles.profileSavePathMatches({}, 'module', 'notifications', ['geometry', 'notifications']), true, 'module scope includes notification geometry');

const resets = load('js/settings/SettingsResets.js', 'resetNotificationsSettings, resetModule');
const profileValues = {
  notificationsDefaultTimeout: 9000, notificationsCriticalTimeout: 2000, notificationsTimeoutIndicatorColor: '#123456', notificationsTimeoutIndicatorStyle: 'border', notificationsTimeoutIndicatorDirection: 'counterclockwise', notificationsCardWidth: 440,
  notificationsCardSpacing: 14, notificationsImageHeight: 160, notificationsBackgroundColor: '#aa332211',
  notificationsSummaryFont: 'Noto Sans', notificationsSummaryFontSize: 18, notificationsSummaryColor: '#ccffffff',
  notificationsAppNameFont: 'Noto Sans', notificationsAppNameFontSize: 13, notificationsAppNameColor: '#aa112233', notificationsAppNameBold: true,
  notificationsLeadingVisualSize: 64, notificationsLeadingVisualRadius: 18, notificationsCardPadding: 17,
  notificationsBodyFont: 'Noto Sans', notificationsBodyFontSize: 16, notificationsBodyColor: '#bb223344', notificationsShowAppIcon: false, notificationsShowAppIconBackground: false, notificationsShowBodyImages: false,
  notificationsShowProgress: false
};
const profileSettings = Object.assign({}, profileValues);
profileSettings.notificationsVerticalAnchor = 'bottom';
const resetConfig = Object.fromEntries(fields.map(field => [field, 'changed']));
resetConfig.notificationsVerticalAnchor = 'top';
let saveCount = 0;
const resetOwner = {
  activeProfile: 'Work', profiles: { Work: {} },
  defaultConfig: { notificationsTimeoutIndicatorColor: "", notificationsTimeoutIndicatorStyle: "bar", notificationsTimeoutIndicatorDirection: "clockwise" },
  expandedProfileData: () => ({ ...profileSettings, geometry: { notifications: [41, 52, 440, 0] } }),
  geometry: { notifications: [8, 9, 380, 0] }, defaultGeometry: { notifications: [-999999, 16, 380, 0] },
  save: () => { saveCount += 1; },
  resetUnavailable: message => { throw new Error(message); }
};
resets.resetNotificationsSettings(resetOwner, resetConfig);
for (const field of fields.filter(field => field !== 'notificationsCardWidth')) assert.strictEqual(resetConfig[field], profileSettings[field], `reset restores ${field} from the active profile`);
assert.strictEqual(resetConfig.notificationsCardWidth, 'changed', 'Notifications content reset leaves the module width untouched');
assert.strictEqual(resetConfig.notificationsVerticalAnchor, 'bottom', 'Notifications page reset restores vertical anchoring');
assert.strictEqual(resetConfig.notificationsTimeoutIndicatorColor, '#123456', 'Notifications page reset restores timeout indicator color');
assert.strictEqual(resetConfig.notificationsTimeoutIndicatorStyle, 'border', 'Notifications page reset restores timeout indicator style');
assert.strictEqual(resetConfig.notificationsTimeoutIndicatorDirection, 'counterclockwise', 'Notifications page reset restores timeout indicator direction');
assert.strictEqual(resetConfig.notificationsBackgroundColor, '#aa332211', 'Notifications page reset restores the independent background color');
assert.strictEqual(resetConfig.notificationsSummaryFont, 'Noto Sans', 'Notifications page reset restores summary font');
assert.strictEqual(resetConfig.notificationsSummaryFontSize, 18, 'Notifications page reset restores summary font size');
assert.strictEqual(resetConfig.notificationsSummaryColor, '#ccffffff', 'Notifications page reset restores summary color');
assert.strictEqual(resetConfig.notificationsAppNameFont, 'Noto Sans', 'Notifications page reset restores application-name font');
assert.strictEqual(resetConfig.notificationsAppNameFontSize, 13, 'Notifications page reset restores application-name font size');
assert.strictEqual(resetConfig.notificationsAppNameColor, '#aa112233', 'Notifications page reset restores application-name color');
assert.strictEqual(resetConfig.notificationsAppNameBold, true, 'Notifications page reset restores application-name bold style');
assert.strictEqual(resetConfig.notificationsLeadingVisualSize, 64, 'Notifications page reset restores leading visual size');
assert.strictEqual(resetConfig.notificationsLeadingVisualRadius, 18, 'Notifications page reset restores leading visual radius');
assert.strictEqual(resetConfig.notificationsCardPadding, 17, 'Notifications page reset restores card padding');
assert.strictEqual(resetConfig.notificationsBodyFont, 'Noto Sans', 'Notifications page reset restores body font family');
assert.strictEqual(resetConfig.notificationsBodyFontSize, 16, 'Notifications page reset restores body font size');
assert.strictEqual(resetConfig.notificationsBodyColor, '#bb223344', 'Notifications page reset restores body color');
assert.deepStrictEqual(Array.from(resetOwner.geometry.notifications), [8, 9, 380, 0], 'notification page reset leaves module geometry untouched');
assert.strictEqual(saveCount, 1, 'reset persists the restored notification settings once');

const moduleProfile = { modules: { notifications: false }, notificationsCardWidth: 460, notificationsVerticalAnchor: 'bottom', notificationsBackgroundColor: '#aa332211', notificationsSummaryFont: 'Noto Sans', notificationsSummaryFontSize: 18, notificationsSummaryColor: '#ccffffff', notificationsAppNameFont: 'Noto Sans', notificationsAppNameFontSize: 13, notificationsAppNameColor: '#aa112233', notificationsAppNameBold: true, notificationsLeadingVisualSize: 64, notificationsLeadingVisualRadius: 18, notificationsCardPadding: 17, notificationsBodyFont: 'Noto Sans', notificationsBodyFontSize: 16, notificationsBodyColor: '#bb223344', geometry: { notifications: [71, 82, 440, 320] } };
const moduleOwner = {
  activeProfile: 'Work', profiles: { Work: {} }, defaultConfig: { notificationsTimeoutIndicatorColor: "", notificationsTimeoutIndicatorStyle: "bar", notificationsTimeoutIndicatorDirection: "clockwise" }, expandedProfileData: () => moduleProfile,
  notifications: true, geometry: {}, defaultGeometry: { notifications: [-999999, 16, 380, 0] },
  moduleFrames: {}, moduleBackgrounds: {}, moduleBlurEnabled: {}, moduleMonitors: {}, defaultModuleBlurEnabled: {}, save: () => { saveCount += 1; }
};
const moduleConfig = { notificationsCardWidth: 380, notificationsVerticalAnchor: 'top', notificationsBackgroundColor: '#4d000000', notificationsSummaryFont: '', notificationsSummaryFontSize: 14, notificationsSummaryColor: '#ffffff', notificationsAppNameFont: '', notificationsAppNameFontSize: 11, notificationsAppNameColor: '', notificationsAppNameBold: false, notificationsLeadingVisualSize: 48, notificationsLeadingVisualRadius: 10, notificationsCardPadding: 12, notificationsBodyFont: '', notificationsBodyFontSize: 12, notificationsBodyColor: '' };
resets.resetModule(moduleOwner, moduleConfig, 'notifications');
assert.strictEqual(moduleConfig.notificationsTimeoutIndicatorColor, '', 'legacy module profile reset falls back to inherited timeout indicator color');
assert.strictEqual(moduleConfig.notificationsTimeoutIndicatorStyle, 'bar', 'legacy module profile reset falls back to strip style');
assert.strictEqual(moduleConfig.notificationsTimeoutIndicatorDirection, 'clockwise', 'legacy module profile reset falls back to clockwise direction');
assert.strictEqual(moduleOwner.notifications, false, 'module reset restores Notifications enabled/disabled state');
assert.deepStrictEqual(Array.from(moduleOwner.geometry.notifications), [71, 82, 460, 320], 'module reset restores notification X/Y and dimensions');
assert.strictEqual(moduleConfig.notificationsCardWidth, 460, 'module reset keeps legacy width synchronized');
assert.strictEqual(moduleConfig.notificationsVerticalAnchor, 'bottom', 'module reset restores the selected vertical anchor');
assert.strictEqual(moduleConfig.notificationsBackgroundColor, '#aa332211', 'module reset restores the notification background color');
assert.strictEqual(moduleConfig.notificationsSummaryFont, 'Noto Sans', 'module reset restores summary font');
assert.strictEqual(moduleConfig.notificationsSummaryFontSize, 18, 'module reset restores summary font size');
assert.strictEqual(moduleConfig.notificationsSummaryColor, '#ccffffff', 'module reset restores summary color');
assert.strictEqual(moduleConfig.notificationsLeadingVisualSize, 64, 'module reset restores leading visual size');
assert.strictEqual(moduleConfig.notificationsAppNameFont, 'Noto Sans', 'module reset restores application-name font');
assert.strictEqual(moduleConfig.notificationsAppNameFontSize, 13, 'module reset restores application-name font size');
assert.strictEqual(moduleConfig.notificationsAppNameColor, '#aa112233', 'module reset restores application-name color');
assert.strictEqual(moduleConfig.notificationsAppNameBold, true, 'module reset restores application-name bold style');
assert.strictEqual(moduleConfig.notificationsLeadingVisualRadius, 18, 'module reset restores leading visual radius');
assert.strictEqual(moduleConfig.notificationsCardPadding, 17, 'module reset restores card padding');
assert.strictEqual(moduleConfig.notificationsBodyFont, 'Noto Sans', 'module reset restores body font family');
assert.strictEqual(moduleConfig.notificationsBodyFontSize, 16, 'module reset restores body font size');
assert.strictEqual(moduleConfig.notificationsBodyColor, '#bb223344', 'module reset restores body color');

const geometry = load('js/NotificationsGeometry.js', 'resolvedCoordinate, migrateLegacyPlacement, normalizeGeometry');
assert.strictEqual(geometry.resolvedCoordinate([-999999, 16, 380, 0], 0, 1920, 380, 16), 1524, 'auto default X preserves previous top-right default as a numeric coordinate');
assert.strictEqual(geometry.resolvedCoordinate([123, 456, 380, 0], 0, 1920, 380, 16), 123, 'explicit X remains an absolute coordinate');
assert.strictEqual(geometry.resolvedCoordinate([123, 456, 380, 0], 1, 1920, 380, 16), 456, 'explicit Y remains an absolute coordinate');
assert.deepStrictEqual(Array.from(geometry.migrateLegacyPlacement('bottom-left', 41, 27, 1920, 1080, 380, 180)), [41, 873, 380, 0], 'legacy bottom-left is converted once into absolute X/Y');
assert.deepStrictEqual(Array.from(geometry.normalizeGeometry([12, 24, 400, 200], 380)), [12, 24, 380, 200], 'normalization preserves optional maximum height alongside absolute position');

console.log('Notifications absolute X/Y geometry, one-time legacy migration, persistence, profile scope and reset: OK');
JS
