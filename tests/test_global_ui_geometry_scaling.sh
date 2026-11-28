#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'NODE'
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const root = process.argv[2];
const read = p => fs.readFileSync(path.join(root, p), 'utf8');
const config = read('Config.qml');
const defaults = read('js/settings/SettingsDefaults.js');
const persistence = read('js/settings/SettingsPersistence.js');
const resets = read('js/settings/SettingsResets.js');
const host = read('components/WidgetWindow.qml');
const dashboard = read('components/Dashboard.qml');
const launcher = read('components/launcher/Launcher.qml');
const osd = read('components/osd/SystemOsd.qml');
const notifications = read('components/notifications/Notifications.qml');
const timerOptions = read('components/TimerOptions.qml');
const shell = read('shell.qml');
const general = read('components/settings/sections/SettingsInterfaceSection.qml');
const settingsWindow = read('components/settings/sections/SettingsWindowSection.qml');
const settingsCombo = read('components/settings/primitives/SettingsComboBox.qml');
const moduleLayoutEditor = read('components/ModuleLayoutEditorWindow.qml');
const layoutEditorProxy = read('components/LayoutEditorProxyWindow.qml');
const layoutEditor = read('components/LayoutEditorWindow.qml');

for (const key of ['uiScale', 'settingsUiScale']) {
  assert.match(config, new RegExp(`property int ${key}: 100`), `${key} defaults to 100%`);
  assert.match(defaults, new RegExp(`${key}: 100`), `${key} belongs to defaults`);
  assert.ok(persistence.includes(`${key}: config.${key}`), `${key} is persisted`);
  assert.ok(resets.includes(`"${key}"`), `${key} belongs to the matching reset scope`);
}
assert.match(config, /function moduleUiScale\(\)[\s\S]*?Math\.max\(75, Math\.min\(150, value\)\) \/ 100/);
assert.match(config, /function settingsUiScaleFactor\(\)[\s\S]*?Math\.max\(75, Math\.min\(150, value\)\) \/ 100/);
assert.match(host, /implicitWidth:\s*Math\.max\(1, root\.visualContentWidth \+ root\.visibilityOverscanPhysicalX \* 2\)/);
assert.match(host, /implicitHeight:\s*Math\.max\(1, root\.visualContentHeight \+ root\.visibilityOverscanPhysicalY \* 2\)/);
assert.match(host, /x: root\.visibilityOverscanPhysicalX[\s\S]*?y: root\.visibilityOverscanPhysicalY[\s\S]*?width: root\.contentWidth[\s\S]*?height: root\.contentHeight[\s\S]*?scale: root\.surfaceScale[\s\S]*?transformOrigin: Item\.TopLeft/,
  'WidgetWindow scales logical content and its physical surface together');
assert.ok(host.includes('root.moduleName === "settings"') && host.includes('Config.settingsUiScaleFactor()'),
  'Settings window has independent geometry scaling');
assert.ok(dashboard.includes('scale: root.drawerUiScale') && dashboard.includes('transformOrigin: Item.TopLeft'),
  'Dashboard drawer is scaled from its top-left anchor');
assert.ok(dashboard.includes('drawer.width * root.drawerUiScale') && dashboard.includes('Number(mouse.x) * root.drawerUiScale'),
  'Dashboard layout editing uses visual dimensions and scaled pointer deltas');
assert.ok(dashboard.includes('Math.round(7 * root.drawerUiScale)')
  && dashboard.includes('Math.round(16 * root.drawerUiScale)'),
  'Dashboard layout-edit label geometry follows drawer scale');
assert.ok(dashboard.includes('width: Math.min(300 * root.drawerUiScale, dashboardHistoryContent.width * root.drawerUiScale)')
  && dashboard.includes('height: Math.min(330 * root.drawerUiScale'),
  'Dashboard history filter popup scales independently on the overlay surface');
assert.ok(settingsCombo.includes('readonly property real popupUiScale: Config.settingsUiScaleFactor()')
  && settingsCombo.includes('width: parent.width * root.popupUiScale')
  && settingsCombo.includes('height: Math.round(30 * root.popupUiScale)'),
  'Settings ComboBox popup geometry follows the independent Settings UI scale');
assert.ok(host.includes('Math.round((Config.frameBorderWidth + 1) * root.surfaceScale)')
  && host.includes('Math.round(5 * root.surfaceScale)'),
  'WidgetWindow layout-edit border and label follow the rendered surface scale');
assert.ok(moduleLayoutEditor.includes('Config.moduleUiScale()')
  && layoutEditorProxy.includes('Config.moduleUiScale()')
  && layoutEditor.includes('Config.settingsUiScaleFactor()'),
  'layout-edit proxy decorations use the matching module or Settings scale');
assert.ok(launcher.includes('(entranceReady ? 1.0 : 0.97) * root.launcherUiScale'),
  'Launcher composes UI scale with its existing entrance animation');
assert.ok(launcher.includes('Number(mouse.x) * root.layoutDragScale'), 'Launcher drag math is scale-aware');
assert.ok(osd.includes('Config.moduleUiScale()'), 'OSD geometry follows module UI scale');
assert.ok(shell.includes('id: timerOptionsScaleHost') && shell.includes('scale: Config.moduleUiScale()') && shell.includes('TimerOptions {\n                    id: timerOptionsPopup'),
  'Timer options popup scales as one surface without changing stored geometry');
assert.ok(shell.includes('scale: Config.moduleUiScale()') && shell.includes('transformOrigin: Item.Center'),
  'timer finished popup scales around its center');
assert.ok(notifications.includes('notificationCardBaseWidth') && notifications.includes('* notificationUiScale'),
  'notification cards scale without changing stored logical geometry');
assert.ok(notifications.includes('notificationCardSpacing') && notifications.includes('Math.round(Number(Config.notificationsCardSpacing) * notificationUiScale)'),
  'notification queue spacing follows module UI scale');
assert.ok(notifications.includes('notificationFrameRadius') && notifications.includes('Math.round(Config.scaledCornerRadius(Config.frameRadius) * notificationUiScale)'),
  'notification card and preview radii follow module UI scale');
assert.ok(notifications.includes('notificationFrameBorderWidth') && notifications.includes('Config.cardBordersEnabled') && notifications.includes('Math.round(Config.frameBorderWidth * notificationUiScale)'),
  'notification card borders follow module UI scale');
assert.ok(notifications.includes('notificationScrollbarWidth') && notifications.includes('notificationTimeoutIndicatorHeight'),
  'notification scrollbar and timeout indicator follow module UI scale');
assert.ok(notifications.includes('Math.round(24 * root.notificationUiScale)'),
  'notification close affordance follows module UI scale');
assert.ok(shell.includes('Settings.geometry.mopidy[2] * Config.moduleUiScale()'),
  'Mopidy hover strip remains aligned with the scaled surface');
assert.ok(general.includes('targetProperty: "uiScale"') && general.includes('targetProperty: "fontScale"'),
  'module UI/font scale controls are exposed');
assert.ok(settingsWindow.includes('targetProperty: "settingsUiScale"') && settingsWindow.includes('targetProperty: "settingsFontScale"'),
  'Settings UI/font scale controls are exposed');
console.log('PASS: geometry scale covers module windows, Dashboard, Launcher, OSD and notifications; Settings retains independent scaling.');
NODE
