#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'JS'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const read = relative => fs.readFileSync(path.join(root, relative), 'utf8');
const runtime = read('components/notifications/Notifications.qml');
const modules = read('components/settings/sections/SettingsModulesSection.qml');
const settings = read('components/settings/sections/SettingsInterfaceSection.qml');

assert(runtime.includes('readonly property int notificationFrameBorderWidth: Settings.moduleFrames.notifications !== false && Config.cardBordersEnabled'),
  'notification frame respects the per-module frame switch and the global card-border master switch');
assert(runtime.includes('? Math.max(1, Math.round(Config.frameBorderWidth * notificationUiScale)) : 0'),
  'notification frame width follows configured border width and module UI scale');
assert.strictEqual((runtime.match(/border\.width: root\.notificationFrameBorderWidth/g) || []).length, 2,
  'live cards and the smart-edit preview use the same effective frame width');
assert(modules.includes('checked: settings.moduleFrames[moduleRow.moduleName] !== false'),
  'the Notifications frame checkbox follows the shared enabled-by-default map');
assert(modules.includes('values[moduleRow.moduleName] = checked') && modules.includes('settings.moduleFrames = values'),
  'the Notifications frame checkbox changes only the selected module map entry');
assert(settings.includes('checked: Config.cardBordersEnabled') && settings.includes('Config.cardBordersEnabled = checked'),
  'the global card-border master switch remains independently available');
assert(runtime.includes('Settings.moduleBackgrounds.notifications !== false ? Config.notificationsBackgroundColor : Config.transparent'),
  'the background toggle does not control frame visibility');
assert(runtime.includes('Settings.moduleBlurEnabled.notifications === true'),
  'blur remains an independent surface option');
console.log('Notifications per-module/global frame toggles, smart-edit preview and independent background/blur: OK');
JS
