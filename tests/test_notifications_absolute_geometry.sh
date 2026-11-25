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
const helperSource = read('js/NotificationsGeometry.js').replace(/^\.pragma library\s*$/gm, '');
const context = {};
vm.runInNewContext(helperSource + '\nthis.api = { resolvedCoordinate, migrateLegacyPlacement, normalizeGeometry };', context);
const geometry = context.api;

assert.strictEqual(geometry.resolvedCoordinate([-999999, 16, 380, 0], 0, 1920, 380, 16), 1524, 'automatic default X is resolved to a concrete coordinate');
assert.strictEqual(geometry.resolvedCoordinate([214, 125, 380, 0], 0, 1920, 380, 16), 214, 'explicit X is not treated as an edge margin');
assert.strictEqual(geometry.resolvedCoordinate([214, 125, 380, 0], 1, 1920, 380, 16), 125, 'explicit Y is not treated as an edge margin');
assert.deepStrictEqual(Array.from(geometry.migrateLegacyPlacement('top-right', 16, 16, 1920, 1080, 380, 160)), [1524, 16, 380, 0], 'legacy top-right is converted to concrete X/Y');
assert.deepStrictEqual(Array.from(geometry.migrateLegacyPlacement('bottom-left', 41, 27, 1920, 1080, 380, 180)), [41, 873, 380, 0], 'legacy bottom-left is converted to concrete X/Y');
assert.deepStrictEqual(Array.from(geometry.normalizeGeometry([214, 125, 400, 200], 380)), [214, 125, 380, 200], 'notification geometry preserves an optional maximum window height');
assert.deepStrictEqual(Array.from(geometry.normalizeGeometry([214, 125, 400, 0], 380)), [214, 125, 380, 0], 'zero retains content-driven automatic height');

const qml = read('components/notifications/Notifications.qml');
const popup = qml.slice(qml.indexOf('PanelWindow {\n        id: popupWindow'), qml.indexOf('Item {\n            id: notificationContent'));
assert(popup.includes('anchors.left: true') && popup.includes('anchors.top: String(Config.notificationsVerticalAnchor || \"top\") !== \"bottom\"'), 'notifications window keeps the left anchor and supports a top anchor');
assert(popup.includes('margins.left: root.notificationCoordinate(0)') && popup.includes('margins.top:') && popup.includes('margins.bottom:'), 'window position uses X and the selected vertical edge inset');
assert(!popup.includes('anchors.right:') && popup.includes('anchors.bottom: String(Config.notificationsVerticalAnchor || \"top\") === \"bottom\"'), 'horizontal right anchoring is removed while bottom anchoring remains available');
assert(!popup.includes('notificationsPosition') && !popup.includes('notificationsOffset'), 'active panel positioning only uses the new vertical anchor setting');
assert(qml.includes('Settings.moduleMonitors') && qml.includes('notificationTargetScreen'), 'coordinates are resolved against the module target monitor');
assert(qml.includes('migrateLegacyNotificationCoordinates'), 'legacy position migration is one-time');

const modules = read('components/settings/sections/SettingsModulesSection.qml');
assert(modules.includes('notificationsGeometryValue(index)') && modules.includes('writeNotificationsGeometry(index, n)'), 'Modules page edits notification X/Y and dimensions through the shared row');
assert(!modules.includes('Привязка к углу') && !modules.includes('Отступ по горизонтали') && !modules.includes('notificationsPositionCombo'), 'legacy four-corner controls are not duplicated in Modules');
assert(modules.includes('model: settings.moduleNames.filter(function(name) { return name !== \"dashboard\" })') && modules.includes('modulesSection.writeNotificationsGeometry(index, n)'), 'notification fields share the common module row');
assert(modules.includes('? (index === 2 ? 280 : (index === 3 ? 0 : -10000))') && modules.includes('? (index === 2 ? 600 : (index === 3 ? 10000 : 10000))'), 'notification X/Y and size bounds are preserved in common fields');

console.log('Notifications X/vertical-edge placement, legacy conversion and module-screen placement: OK');
JS
