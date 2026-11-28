#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'NODE'
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const root = process.argv[2];
const read = rel => fs.readFileSync(path.join(root, rel), 'utf8');
const config = read('Config.qml');
const defaults = read('js/settings/SettingsDefaults.js');
const persistence = read('js/settings/SettingsPersistence.js');
const apply = read('js/settings/SettingsApplyBehaviour.js');
const schema = read('js/settings/SettingsSchema.js');
const resets = read('js/settings/SettingsResets.js');
const profiles = read('js/settings/SettingsProfiles.js');
const settings = read('Settings.qml');
const page = read('components/settings/sections/SettingsOsdSection.qml');
const osd = read('components/osd/SystemOsd.qml');
const check = read('CHECK.sh');
const key = 'osdIntegrateWithNotifications';

assert.match(config, /property bool osdIntegrateWithNotifications: false/,
  'integration is opt-in to preserve legacy OSD behavior');
assert.match(defaults, /osdIntegrateWithNotifications:\s*false/,
  'new profiles default to the separate OSD presentation');
assert.ok(persistence.includes(`${key}: config.${key} === true`),
  'integration preference is persisted into profiles');
assert.match(apply, /if \(o\.osdIntegrateWithNotifications !== undefined\)[\s\S]*?Config\.osdIntegrateWithNotifications = o\.osdIntegrateWithNotifications === true/,
  'profile restoration applies the boolean explicitly');
assert.match(schema, /if \(p\.osdIntegrateWithNotifications !== undefined\)[\s\S]*?typeof p\.osdIntegrateWithNotifications === "boolean"[\s\S]*?else if \(!isSparse\)[\s\S]*?p\.osdIntegrateWithNotifications = false/,
  'legacy/full profiles normalize safely while sparse profiles omit defaults');
assert.match(page, /heading: "Интеграция с уведомлениями"[\s\S]*?text: "Интегрировать OSD с уведомлениями"[\s\S]*?Config\.osdIntegrateWithNotifications = checked/,
  'OSD page exposes the requested toggle');
assert.match(page, /visible: root\.visible[\s\S]*?heading: "Интеграция с уведомлениями"/,
  'shared integration option is visible across all OSD subtabs');
assert.match(settings, /if \(scope === "osd"\)[\s\S]*?hasAny\(\["osdIntegrateWithNotifications"\]\)/,
  'page-level Save/Reset dirty state includes the integration option');
assert.match(profiles, /if \(scope === "osd"\) return root === "osdIntegrateWithNotifications"/,
  'OSD profile save scope includes the integration option');
assert.match(resets, /"osdIntegrateWithNotifications"/,
  'OSD reset copies the integration option from the active profile');
assert.match(resets, /osdIntegrateWithNotifications:\s*false/,
  'OSD reset has a deterministic fallback for older profiles');
assert.match(osd, /NotificationAnimation\.effectiveStyle\(Config\.animationNotificationsVisibilityProfile, Config\.animationNotificationsVisibilityStyle\)/,
  'integrated OSD uses the notification visibility animation style');
assert.match(osd, /Settings\.notificationsWindowHeight/,
  'integrated OSD follows the active notification stack height');
assert.match(osd, /integratedCardHeight: Math\.max\([\s\S]*?notificationLeadingVisualSize[\s\S]*?integratedTextBlockHeight[\s\S]*?notificationCardPadding/,
  'integrated card height grows for larger fonts, module scale and notification padding');
assert.match(osd, /integratedVolumeLineHeight: Math.max\(Config\.uiFontSize\(14\)/,
  'integrated volume label reserves enough height for the larger percentage and mute text');
assert.match(osd, /presentationMode === "media" \? 80 : 72/,
  'integrated notification-style OSD uses a compact baseline card height');
assert.match(osd, /Layout\.preferredWidth: Math\.round\(54 \* root\.notificationUiScale\)[\s\S]*?text: root\.muted \? "Mute" : String\(Math\.round\(root\.volume\)\) \+ "%"[\s\S]*?font\.pixelSize: Config\.uiFontSize\(14\)/,
  'volume percentage and Mute label are larger and have enough horizontal space');
assert.match(osd, /NotificationsGeometry\.resolvedCoordinate\([\s\S]*?root\.notificationGeometry/,
  'integrated OSD shares notification X/Y geometry resolution');
assert.match(osd, /anchors\.top: !root\.notificationIntegrationEnabled \|\| !root\.notificationBottomAnchored[\s\S]*?anchors\.bottom: root\.notificationIntegrationEnabled && root\.notificationBottomAnchored/,
  'integrated OSD follows the notification top/bottom anchor');
assert.match(osd, /root\.notificationStackHeight \+ root\.notificationStackGap/,
  'integrated OSD leaves a gap after the active notification stack');
assert.match(osd, /Settings\.moduleBackgrounds\.notifications !== false \? Config\.notificationsBackgroundColor/,
  'integrated OSD uses notification background settings');
assert.match(osd, /root\.notificationFrameBorderWidth/,
  'integrated OSD uses notification border settings');
assert.match(osd, /visible: !root\.notificationIntegrationEnabled && root\.presentationMode === "media"/,
  'legacy media presentation remains available when integration is disabled');
assert.match(osd, /visible: !root\.notificationIntegrationEnabled && root\.presentationMode === "dnd"/,
  'legacy DND presentation remains available when integration is disabled');
assert.match(osd, /visible: !root\.notificationIntegrationEnabled && root\.presentationMode === "volume"/,
  'legacy volume presentation remains available when integration is disabled');
assert.ok(check.includes('test_osd_notifications_integration.sh'),
  'integration audit test is registered in CHECK.sh');

function evaluate(source, exportName, names, extra = {}) {
  const context = {...extra};
  vm.createContext(context);
  vm.runInContext(source.replace(/^\.pragma library\s*/m, '') + `\nthis.${exportName} = {${names.join(',')}};`, context);
  return context[exportName];
}
const schemaApi = evaluate(schema, 'api', ['normalizeProfile']);
const fullProfile = schemaApi.normalizeProfile({osdIntegrateWithNotifications: 'true'}, false);
assert.equal(fullProfile.osdIntegrateWithNotifications, false,
  'malformed values in a full profile normalize to false');
const sparseProfile = schemaApi.normalizeProfile({osdIntegrateWithNotifications: true}, true);
assert.equal(sparseProfile.osdIntegrateWithNotifications, true,
  'valid sparse overrides preserve true');
const sparseMissing = schemaApi.normalizeProfile({}, true);
assert.equal(Object.hasOwn(sparseMissing, 'osdIntegrateWithNotifications'), false,
  'sparse profiles do not materialize the default');

const resetsApi = evaluate(resets, 'api', ['resetOsdDefaults']);
const target = {osdIntegrateWithNotifications: true};
resetsApi.resetOsdDefaults({defaultConfig: {osdIntegrateWithNotifications: false}}, target, {});
assert.equal(target.osdIntegrateWithNotifications, false,
  'OSD defaults reset restores false when older profiles omit the key');

console.log('OSD/Notifications integration setting, profile lifecycle, reset and presentation contract: OK');
NODE
