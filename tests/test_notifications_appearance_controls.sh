#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'JS'
const fs = require('fs');
const vm = require('vm');
const path = require('path');
const assert = require('assert');
const root = process.argv[2];
const read = p => fs.readFileSync(path.join(root, p), 'utf8');
const config = read('Config.qml');
const defaults = read('js/settings/SettingsDefaults.js');
const schemaSource = read('js/settings/SettingsSchema.js').replace(/^\.pragma library\s*/, '');
const schema = vm.runInThisContext(schemaSource + '\n({ normalizeProfile })');
const persistence = read('js/settings/SettingsPersistence.js');
const apply = read('js/settings/SettingsApplyCore.js');
const resets = read('js/settings/SettingsResets.js');
const navigation = read('components/settings/SettingsNavigationController.qml');
const section = read('components/settings/sections/SettingsNotificationsSection.qml');
const runtime = read('components/notifications/Notifications.qml');

const keys = [
  'notificationsAppNameFont', 'notificationsAppNameFontSize', 'notificationsAppNameColor',
  'notificationsAppNameBold', 'notificationsLeadingVisualRadius', 'notificationsCardPadding',
  'notificationsBodyFontSize', 'notificationsBodyColor'
];
for (const key of keys) {
  assert(config.includes(key), `Config is missing ${key}`);
  assert(defaults.includes(key), `profile defaults are missing ${key}`);
  assert(persistence.includes(key), `snapshot omits ${key}`);
  assert(apply.includes(`o.${key}`), `profile apply omits ${key}`);
  assert(resets.includes(`"${key}"`), `reset scope omits ${key}`);
  assert(navigation.includes(`"${key}"`), `dirty/search tracking omits ${key}`);
  assert(section.includes(key), `Settings UI omits ${key}`);
  assert(runtime.includes(key), `notification renderer omits ${key}`);
}
assert(section.includes('heading: "Название приложения"'), 'application-name typography group is missing');
assert(section.includes('heading: "Скругление иконки / аватара"'), 'leading visual radius group is missing');
assert(section.includes('heading: "Внутренние отступы карточки"'), 'card padding group is missing');
assert(section.includes('heading: "Основной текст уведомления"'), 'body typography group is missing');
assert(runtime.includes('font.family: Config.notificationsAppNameFont'), 'app label font family is not applied');
assert(runtime.includes('font.bold: Config.notificationsAppNameBold'), 'app label weight is not applied');
assert(runtime.includes('Config.notificationsAppNameColor || Config.text'), 'app label must inherit the active theme color when unset');
assert(runtime.includes('root.notificationLeadingVisualRadius'), 'icon/avatar radius is not applied');
assert(runtime.includes('root.notificationCardPadding'), 'card padding is not applied to layout');
assert(runtime.includes('? root.notificationImageGap : root.notificationCardPadding'), 'standalone body image respects the configured top inset');
assert(runtime.includes('root.notificationCardWidth - root.notificationCardPadding * 2'), 'body image decode width follows the configured horizontal insets');
assert(runtime.includes('font.pixelSize: root.notificationBodyFontSize'), 'body font size is not applied');
assert(runtime.includes('Config.notificationsBodyColor || Config.text'), 'body color must inherit the active theme when unset');

let full = schema.normalizeProfile({}, false);
assert.strictEqual(full.notificationsAppNameFont, '');
assert.strictEqual(full.notificationsAppNameFontSize, 11);
assert.strictEqual(full.notificationsAppNameColor, '');
assert.strictEqual(full.notificationsAppNameBold, false);
assert.strictEqual(full.notificationsLeadingVisualRadius, 10);
assert.strictEqual(full.notificationsCardPadding, 12);
assert.strictEqual(full.notificationsBodyFontSize, 12);
assert.strictEqual(full.notificationsBodyColor, '');
let bounded = schema.normalizeProfile({
  notificationsAppNameFontSize: 999,
  notificationsLeadingVisualRadius: -5,
  notificationsCardPadding: 500,
  notificationsBodyFontSize: 1,
  notificationsAppNameColor: '#AABBCCDD',
  notificationsBodyColor: '#DDEEFF'
}, false);
assert.strictEqual(bounded.notificationsAppNameFontSize, 24);
assert.strictEqual(bounded.notificationsLeadingVisualRadius, 0);
assert.strictEqual(bounded.notificationsCardPadding, 32);
assert.strictEqual(bounded.notificationsBodyFontSize, 8);
assert.strictEqual(bounded.notificationsAppNameColor, '#aabbccdd');
assert.strictEqual(bounded.notificationsBodyColor, '#ddeeff');
let sparse = schema.normalizeProfile({}, true);
for (const key of keys) assert.strictEqual(sparse[key], undefined, `sparse profile should inherit ${key}`);
let sparseOverride = schema.normalizeProfile({ notificationsAppNameBold: false, notificationsLeadingVisualRadius: 0 }, true);
assert.strictEqual(sparseOverride.notificationsAppNameBold, false, 'explicit false boolean override must survive');
assert.strictEqual(sparseOverride.notificationsLeadingVisualRadius, 0, 'square icon override must survive');
console.log('Notifications application-name typography, leading radius, card padding, body typography and profile wiring: OK');
JS
