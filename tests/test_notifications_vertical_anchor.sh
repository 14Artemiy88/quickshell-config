#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'JS'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const root = process.argv[2];
const read = name => fs.readFileSync(path.join(root, name), 'utf8');

const helperSource = read('js/NotificationsGeometry.js').replace(/^\.pragma library\s*$/gm, '');
const helperContext = {};
vm.runInNewContext(helperSource + '\nthis.api = { resolvedTopCoordinate, storedVerticalOffset, convertVerticalOffset };', helperContext);
const geometry = helperContext.api;

assert.strictEqual(geometry.resolvedTopCoordinate('top', 16, 1080, 180), 16,
  'top anchoring keeps the inset from the upper edge');
assert.strictEqual(geometry.resolvedTopCoordinate('bottom', 16, 1080, 180), 884,
  'bottom anchoring places the panel by its lower edge');
assert.strictEqual(geometry.storedVerticalOffset('bottom', 884, 1080, 180), 16,
  'smart drag stores the distance from the bottom edge');
assert.strictEqual(geometry.storedVerticalOffset('top', 884, 1080, 180), 884,
  'smart drag keeps the top coordinate in top mode');
assert.strictEqual(geometry.convertVerticalOffset(884, 1080, 180), 16,
  'switching anchors converts the old top coordinate into a bottom inset');
assert.strictEqual(geometry.convertVerticalOffset(16, 1080, 180), 884,
  'switching anchors converts the old bottom inset back into a top coordinate');

const config = read('Config.qml');
const defaults = read('js/settings/SettingsDefaults.js');
const persistence = read('js/settings/SettingsPersistence.js');
const apply = read('js/settings/SettingsApplyCore.js');
const settings = read('Settings.qml');
const runtime = read('components/notifications/Notifications.qml');
const page = read('components/settings/sections/SettingsNotificationsSection.qml');
const modules = read('components/settings/sections/SettingsModulesSection.qml');
const tabs = read('components/settings/SettingsWidget.qml');
const registry = read('js/settings/SettingsPageRegistry.js');

assert(config.includes('property string notificationsVerticalAnchor: "top"'),
  'Config exposes a top/bottom-only anchor mode');
assert(defaults.includes('notificationsVerticalAnchor: "top"') &&
       persistence.includes('notificationsVerticalAnchor: config.notificationsVerticalAnchor'),
  'anchor is included in defaults and persisted settings');
assert(apply.includes('Config.notificationsVerticalAnchor = verticalAnchor === "bottom" ? "bottom" : "top"'),
  'loaded anchor is validated');
assert(apply.includes('legacyPosition.indexOf("bottom-") === 0'),
  'older bottom-left/right preferences migrate to bottom anchoring');
assert(settings.includes('function setNotificationsVerticalAnchor(anchor)') &&
       settings.includes('NotificationsGeometry.convertVerticalOffset('),
  'anchor changes convert the saved Y inset instead of reinterpreting it blindly');
assert(runtime.includes('anchors.bottom: String(Config.notificationsVerticalAnchor || "top") === "bottom"') &&
       runtime.includes('anchors.top: String(Config.notificationsVerticalAnchor || "top") !== "bottom"'),
  'notification panel can be anchored to either vertical edge');
assert(runtime.includes('NotificationsGeometry.storedVerticalOffset(') &&
       runtime.includes('root.notificationTopCoordinate(popupWindow.screen, popupWindow.height)'),
  'smart editing works with visible panel coordinates and stores the selected edge inset');
assert(runtime.includes('current[1] = Math.max(0, Math.min(500, Math.round(Number(Config.notificationsLegacyOffsetY) || 16)))'),
  'legacy bottom corner migration stores the old vertical edge margin');
assert(page.includes('currentPageSubTabIndex === 2') && page.includes('Вертикальная привязка') &&
       page.includes('model: ["Сверху", "Снизу"]'),
  'vertical anchor control lives on the Notifications page');
assert(registry.includes('{ id: "notifications", saveScope: "notifications", subTabs: ["Поведение", "Внешний вид", "Размещение", "Анимация"] }'),
  'Notifications page keeps the Placement subtab alongside Animation');
assert(modules.includes('model: settings.moduleNames.filter(function(name) { return name !== \"dashboard\" })') &&
       modules.includes('moduleRow.moduleName === "notifications"') &&
       modules.includes('modulesSection.writeNotificationsGeometry(index, n)'),
  'notification module uses the common enabled/X/Y/Width/Height/frame/background/blur/save/reset row');
assert(!modules.includes('id: notificationsModuleGroup'),
  'the separate notification-only control block is removed');

console.log('Notification vertical anchoring, edge-aware smart editing, persistence and common module row: OK');
JS
