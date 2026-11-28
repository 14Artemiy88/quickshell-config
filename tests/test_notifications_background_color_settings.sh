#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
node - "$ROOT" <<'JS'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const root = process.argv[2];
const read = name => fs.readFileSync(path.join(root, name), 'utf8');
const config = read('Config.qml');
const defaults = read('js/settings/SettingsDefaults.js');
const persistence = read('js/settings/SettingsPersistence.js');
const apply = read('js/settings/SettingsApplyCore.js');
const schema = read('js/settings/SettingsSchema.js');
const resets = read('js/settings/SettingsResets.js');
const section = read('components/settings/sections/SettingsNotificationsSection.qml');
const runtime = read('components/notifications/Notifications.qml');
const navigation = read('components/settings/SettingsNavigationController.qml');

assert(config.includes('property color notificationsBackgroundColor: "#4d000000"'), 'Config defines a notification-specific ARGB color');
assert(defaults.includes('notificationsBackgroundColor: "#4d000000"'), 'new profiles receive the same default surface color');
assert(persistence.includes('notificationsBackgroundColor: String(config.notificationsBackgroundColor)'), 'color is included in settings snapshots');
assert(apply.includes('Schema.normalizeSavedColor(o.notificationsBackgroundColor, "#4d000000")'), 'settings loader validates the saved color');
assert(schema.includes('p.notificationsBackgroundColor = normalizeSavedColor(p.notificationsBackgroundColor, "#4d000000")'), 'profile normalization rejects invalid colors');
assert(resets.includes('"notificationsImageHeight", "notificationsBackgroundColor", "notificationsSummaryFont", "notificationsSummaryFontSize", "notificationsSummaryColor", "notificationsAppNameFont", "notificationsAppNameFontSize", "notificationsAppNameColor", "notificationsAppNameBold", "notificationsLeadingVisualSize", "notificationsLeadingVisualRadius", "notificationsCardPadding", "notificationsBodyFont", "notificationsBodyFontSize", "notificationsBodyColor", "notificationsShowAppIcon"'), 'module reset includes all notification appearance settings');
assert(resets.includes('"notificationsImageHeight", "notificationsBackgroundColor", "notificationsSummaryFont", "notificationsSummaryFontSize", "notificationsSummaryColor", "notificationsAppNameFont", "notificationsAppNameFontSize", "notificationsAppNameColor", "notificationsAppNameBold", "notificationsLeadingVisualSize", "notificationsLeadingVisualRadius", "notificationsCardPadding", "notificationsBodyFont", "notificationsBodyFontSize", "notificationsBodyColor", "notificationsShowAppIcon", "notificationsShowAppIconBackground", "notificationsShowBodyImages"'), 'Notifications page reset includes all notification appearance settings');
assert(section.includes('heading: "Фон уведомлений"') && section.includes('targetProperty: "notificationsBackgroundColor"'), 'Settings exposes a dedicated color field');
assert(section.includes('allowAlpha: true') && section.includes('allowTransparent: true'), 'color field supports opacity and transparent mode');
assert(navigation.includes('"notificationsBackgroundColor"'), 'settings search/dirty tracking includes the new color');
assert(runtime.includes('Settings.moduleBackgrounds.notifications !== false ? Config.notificationsBackgroundColor : Config.transparent'), 'module background toggle controls the custom notification surface');

function load(source, expression, extra = {}) {
  const context = { ...extra };
  vm.createContext(context);
  vm.runInContext(source.replace(/^\.pragma library\s*$/gm, '').replace(/^\.import .*$/gm, '') + `\nthis.api = { ${expression} };`, context);
  return context.api;
}
const schemaApi = load(schema, 'normalizeProfile');
assert.strictEqual(schemaApi.normalizeProfile({ notificationsBackgroundColor: '#AABBCCDD' }, false).notificationsBackgroundColor, '#aabbccdd', 'full profiles canonicalize valid ARGB colors');
assert.strictEqual(schemaApi.normalizeProfile({ notificationsBackgroundColor: 'not-a-color' }, false).notificationsBackgroundColor, '#4d000000', 'invalid full-profile colors fall back safely');
assert.strictEqual(schemaApi.normalizeProfile({ notificationsBackgroundColor: 'transparent' }, true).notificationsBackgroundColor, 'transparent', 'sparse profiles retain transparent overrides');
assert.strictEqual(schemaApi.normalizeProfile({}, false).notificationsBackgroundColor, '#4d000000', 'legacy full profiles inherit the built-in notification background');
assert.strictEqual(schemaApi.normalizeProfile({}, true).notificationsBackgroundColor, undefined, 'sparse profiles inherit the background from their base rather than creating an override');
console.log('notifications background color settings, persistence, schema, profile reset: OK');
JS
