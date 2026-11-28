#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'JS'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const root = process.argv[2];
const read = p => fs.readFileSync(path.join(root, p), 'utf8');
const config = read('Config.qml');
const defaults = read('js/settings/SettingsDefaults.js');
const schemaSource = read('js/settings/SettingsSchema.js');
const applySource = read('js/settings/SettingsApplyCore.js');
const persistence = read('js/settings/SettingsPersistence.js');
const resets = read('js/settings/SettingsResets.js');
const section = read('components/settings/sections/SettingsNotificationsSection.qml');
const navigation = read('components/settings/SettingsNavigationController.qml');
const profilesSource = read('js/settings/SettingsProfiles.js');
const runtime = read('components/notifications/Notifications.qml');

function load(source, expression, extra = {}) {
  const context = { ...extra };
  vm.createContext(context);
  vm.runInContext(source.replace(/^\.pragma library\s*$/gm, '').replace(/^\.import .*$/gm, '') + `\nthis.api = { ${expression} };`, context);
  return context.api;
}
const schema = load(schemaSource, 'normalizeProfile');
const fullDefaults = schema.normalizeProfile({}, false);
assert.strictEqual(fullDefaults.notificationsSummaryFont, '', 'legacy full profiles inherit the system font');
assert.strictEqual(fullDefaults.notificationsSummaryFontSize, 14, 'legacy full profiles inherit the old heading size');
assert.strictEqual(fullDefaults.notificationsSummaryColor, '', 'legacy full profiles continue inheriting the active theme text color');
assert.strictEqual(fullDefaults.notificationsLeadingVisualSize, 48, 'legacy full profiles preserve the old leading icon size');
const sparseEmpty = schema.normalizeProfile({}, true);
for (const key of ['notificationsSummaryFont', 'notificationsSummaryFontSize', 'notificationsSummaryColor', 'notificationsLeadingVisualSize'])
  assert.strictEqual(sparseEmpty[key], undefined, `sparse profile inherits ${key} without creating an override`);
const sparse = schema.normalizeProfile({
  notificationsSummaryFont: '  Inter\nUI  ',
  notificationsSummaryFontSize: 99,
  notificationsSummaryColor: '#AABBCCDD',
  notificationsLeadingVisualSize: 16
}, true);
assert.strictEqual(sparse.notificationsSummaryFont, 'Inter UI', 'font family removes control whitespace');
assert.strictEqual(sparse.notificationsSummaryFontSize, 32, 'font size clamps to its upper bound');
assert.strictEqual(sparse.notificationsSummaryColor, '#aabbccdd', 'ARGB title color is canonicalized');
assert.strictEqual(sparse.notificationsLeadingVisualSize, 24, 'leading visual size clamps to its lower bound');
const invalid = schema.normalizeProfile({ notificationsSummaryFont: {}, notificationsSummaryFontSize: 'nope', notificationsSummaryColor: 'bad', notificationsLeadingVisualSize: {} }, true);
assert.strictEqual(invalid.notificationsSummaryFont, undefined, 'invalid sparse font family is omitted');
assert.strictEqual(invalid.notificationsSummaryFontSize, undefined, 'invalid sparse font size is omitted');
assert.strictEqual(invalid.notificationsSummaryColor, undefined, 'invalid sparse color inherits the profile base');
assert.strictEqual(invalid.notificationsLeadingVisualSize, undefined, 'invalid sparse leading size is omitted');

const schemaApi = load(schemaSource, 'normalizeSavedColor');
const apply = load(applySource, 'apply', { Schema: schemaApi });
const loaded = {};
apply.apply({}, loaded, {
  notificationsSummaryFont: 'JetBrains Mono\t',
  notificationsSummaryFontSize: 7,
  notificationsSummaryColor: '#12AB34CD',
  notificationsLeadingVisualSize: 90
});
assert.strictEqual(loaded.notificationsSummaryFont, 'JetBrains Mono', 'settings loader restores normalized font family');
assert.strictEqual(loaded.notificationsSummaryFontSize, 8, 'settings loader clamps font size');
assert.strictEqual(loaded.notificationsSummaryColor, '#12ab34cd', 'settings loader canonicalizes heading ARGB color');
assert.strictEqual(loaded.notificationsLeadingVisualSize, 72, 'settings loader clamps icon/avatar size');

for (const key of ['notificationsSummaryFont', 'notificationsSummaryFontSize', 'notificationsSummaryColor', 'notificationsLeadingVisualSize']) {
  assert(config.includes(` ${key}:`), `Config declares ${key}`);
  assert(defaults.includes(`${key}:`), `profile defaults include ${key}`);
  assert(persistence.includes(`${key}:`), `settings snapshot persists ${key}`);
  assert(applySource.includes(`o.${key}`), `settings loader applies ${key}`);
  assert(resets.includes(`"${key}"`), `page and module reset include ${key}`);
  assert(section.includes(`targetProperty: "${key}"`), `Settings UI edits ${key}`);
  assert(navigation.includes(`"${key}"`), `appearance dirty tracking includes ${key}`);
}
const profileScope = load(profilesSource, 'profileSavePathMatches');
for (const key of ['notificationsSummaryFont', 'notificationsSummaryFontSize', 'notificationsSummaryColor', 'notificationsLeadingVisualSize']) {
  assert.strictEqual(profileScope.profileSavePathMatches({}, 'notifications', null, [key]), true, `${key} participates in scoped page Save`);
  assert.strictEqual(profileScope.profileSavePathMatches({}, 'module', 'notifications', [key]), true, `${key} participates in scoped module Save`);
}
assert(section.includes('SettingsFontField') && section.includes('heading: "Заголовок и иконка"'), 'appearance group uses the shared font field primitive');
assert(section.includes('SettingsColorField') && section.includes('label: "Цвет заголовка"'), 'appearance group uses the shared color field primitive');
assert(section.includes('label: "Размер иконки / аватара"'), 'appearance group exposes a shared leading visual size control');
assert(runtime.includes('font.family: Config.resolveFontFamily(Config.notificationsSummaryFont)'), 'summary measurement uses the selected font family');
assert(runtime.includes('font.pixelSize: Config.uiFontSize(root.notificationSummaryFontSize)'), 'summary display and measurement use selected size');
assert(runtime.includes('color: Config.notificationsSummaryColor || Config.text'), 'summary display uses custom color or inherits the active theme text color');
assert(runtime.includes('width: root.notificationLeadingVisualSize') && runtime.includes('height: root.notificationLeadingVisualSize'), 'leading visual frame uses configured size');
assert(runtime.includes('card.textColumnLeftMargin') && runtime.includes('root.notificationLeadingVisualSize + root.notificationCardPadding * 3'), 'text column and measured width follow the configured leading size');
assert(runtime.includes('root.notificationLeadingVisualSize + root.notificationCardPadding * 2'), 'card minimum height grows to fit larger leading visuals');
console.log('Notifications heading typography, leading visual sizing, profile schema, persistence and reset: OK');
JS
