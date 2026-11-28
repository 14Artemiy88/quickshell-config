#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'NODE'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const root = process.argv[2];
const read = relative => fs.readFileSync(path.join(root, relative), 'utf8');
function load(relative, injected = {}, appended = '') {
  const source = read(relative).replace(/^\.pragma library\s*$/gm, '').replace(/^\.import .*$/gm, '');
  const context = Object.assign({}, injected);
  vm.runInNewContext(source + '\n' + appended, context, { filename: relative });
  return context;
}
const registry = load('js/settings/SettingsPageRegistry.js');
const dragReorder = load('js/utils/DragReorder.js');
const defaultOrder = registry.defaultNavigationOrder();
assert.deepStrictEqual(Array.from(defaultOrder.groupOrder), ['appearance','modules','dashboard','launcher','notifications','general']);
assert.deepStrictEqual(Object.keys(defaultOrder.pagesByGroup).sort(), ['appearance','dashboard','general','launcher','modules','notifications']);
const allPages = Object.values(defaultOrder.pagesByGroup).flat();
assert.strictEqual(allPages.length, 26);
assert.strictEqual(new Set(allPages).size, 26, 'every stable page appears exactly once in the hierarchical default');
assert.deepStrictEqual(Array.from(defaultOrder.pagesByGroup.dashboard), ['dashboard'], 'Dashboard remains a movable singleton frame');
assert.deepStrictEqual(Array.from(defaultOrder.pagesByGroup.general), ['general'], 'General remains a movable singleton frame');

// Legacy flat migration preserves per-group page order, while frame order uses
// the canonical default because the old representation had no frame ordering.
const legacy = ['weather','modules','settingsWindow','themes','calendar','notifications','notificationsDnd','dashboard','launcherSearch','launcher'];
const migrated = registry.navigationOrderFromLegacyTabOrder(legacy);
assert.deepStrictEqual(Array.from(migrated.groupOrder), Array.from(defaultOrder.groupOrder));
assert.deepStrictEqual(Array.from(migrated.pagesByGroup.modules.slice(0, 4)), ['weather','modules','calendar','time']);
assert.deepStrictEqual(Array.from(migrated.pagesByGroup.notifications), ['notifications','notificationsDnd']);
assert.deepStrictEqual(Array.from(migrated.pagesByGroup.appearance), ['settingsWindow','themes','interface']);
assert.deepStrictEqual(Array.from(migrated.pagesByGroup.launcher.slice(0, 2)), ['launcherSearch','launcher']);
assert.deepStrictEqual(Array.from(registry.flattenNavigationOrder(migrated)), [
  'settingsWindow','themes','interface','weather','modules','calendar','time','timers','player','mopidy','cava','cpuRam','network','volume','osd',
  'dashboard','launcherSearch','launcher','launcherTabs','launcherProjects','launcherActions','launcherAnimation','launcherApplications','notifications','notificationsDnd','general'
]);

// Malformed input is normalized: unknown/duplicate groups and pages disappear,
// cross-frame page assignment is rejected, and missing canonical entries return.
const malformed = registry.normalizeNavigationOrder({
  groupOrder: ['general','modules','modules','unknown'],
  pagesByGroup: {
    appearance: ['settingsWindow','settingsWindow','modules'],
    modules: ['weather','weather','calendar','no-such-page'],
    general: []
  }
});
assert.deepStrictEqual(Array.from(malformed.groupOrder), ['general','modules','appearance','dashboard','launcher','notifications']);
assert.deepStrictEqual(Array.from(malformed.pagesByGroup.appearance), ['settingsWindow','themes','interface']);
assert.deepStrictEqual(Array.from(malformed.pagesByGroup.modules.slice(0, 2)), ['weather','calendar']);
assert.strictEqual(Object.values(malformed.pagesByGroup).flat().length, 26);
assert.strictEqual(new Set(Object.values(malformed.pagesByGroup).flat()).size, 26);

// Exercise the actual QML controller method bodies with a tiny host stub.
const controller = read('components/settings/SettingsNavigationController.qml');
function body(name) {
  const start = controller.indexOf(`function ${name}(`);
  assert(start >= 0, `missing controller function ${name}`);
  const open = controller.indexOf('{', start);
  let depth = 0;
  for (let i = open; i < controller.length; i++) {
    if (controller[i] === '{') depth++;
    else if (controller[i] === '}' && --depth === 0) return controller.slice(open + 1, i);
  }
  throw new Error(`unterminated function ${name}`);
}
let navState = JSON.parse(JSON.stringify(defaultOrder));
let saveCount = 0;
const fakeRoot = {
  settingsNavigationOrderNormalized: () => JSON.parse(JSON.stringify(navState)),
  settingsNavigationGroupOrderNormalized: () => navState.groupOrder.slice(),
  settingsNavigationGroupCanMove: (id, delta) => {
    const from = navState.groupOrder.indexOf(id); return from >= 0 && from + delta >= 0 && from + delta < navState.groupOrder.length;
  },
  settingsTabCanMoveWithinGroup: (groupId, id, delta) => {
    if (registry.navigationGroupIdForTabId(id) !== groupId) return false;
    const arr = navState.pagesByGroup[groupId];
    const from = arr.indexOf(id); return from >= 0 && from + delta >= 0 && from + delta < arr.length;
  },
  settings: { save() { saveCount++; } }
};
const config = {};
const moveGroup = new Function('id','delta','root','Config','SettingsPageRegistry','DragReorder', body('moveSettingsNavigationGroup'));
moveGroup('dashboard', -1, fakeRoot, config, registry, dragReorder);
assert.deepStrictEqual(Array.from(config.settingsNavigationOrder.groupOrder), ['appearance','dashboard','modules','launcher','notifications','general']);
assert.deepStrictEqual(Array.from(config.settingsNavigationOrder.pagesByGroup.modules), Array.from(defaultOrder.pagesByGroup.modules));
assert.strictEqual(saveCount, 1, 'moving a frame persists the hierarchical order');
navState = JSON.parse(JSON.stringify(config.settingsNavigationOrder));
const movePage = new Function('groupId','id','delta','root','Config','SettingsPageRegistry','DragReorder', body('moveSettingsTabWithinGroup'));
movePage('modules', 'timers', 1, fakeRoot, config, registry, dragReorder);
assert.deepStrictEqual(Array.from(config.settingsNavigationOrder.pagesByGroup.modules.slice(0, 3)), ['modules','time','player']);
assert.strictEqual(config.settingsNavigationOrder.pagesByGroup.appearance.includes('weather'), false, 'pages cannot move between groups');
assert.strictEqual(saveCount, 2, 'moving a page persists the page order');

const moveGroupTo = new Function('id','toIndex','root','Config','SettingsPageRegistry','DragReorder', body('moveSettingsNavigationGroupTo'));
const movePageTo = new Function('groupId','id','toIndex','root','Config','SettingsPageRegistry','DragReorder', body('moveSettingsTabWithinGroupTo'));
navState = JSON.parse(JSON.stringify(config.settingsNavigationOrder));
assert.strictEqual(moveGroupTo('general', 0, fakeRoot, config, registry, dragReorder), true,
  'drag can move the General singleton frame to an arbitrary final index');
assert.deepStrictEqual(Array.from(config.settingsNavigationOrder.groupOrder), ['general','appearance','dashboard','modules','launcher','notifications']);
assert.strictEqual(movePageTo('notifications', 'notificationsDnd', 0, fakeRoot, config, registry, dragReorder), true,
  'drag can move a page to an arbitrary final index within its frame');
assert.deepStrictEqual(Array.from(config.settingsNavigationOrder.pagesByGroup.notifications.slice(0, 2)), ['notificationsDnd','notifications'],
  'destination index is the final zero-based position in the page list');
const exactBeforeInvalid = JSON.stringify(config.settingsNavigationOrder);
assert.strictEqual(movePageTo('appearance', 'notifications', 0, fakeRoot, config, registry, dragReorder), false,
  'drag cannot move a page into another frame');
assert.strictEqual(moveGroupTo('missing-group', 0, fakeRoot, config, registry, dragReorder), false,
  'drag rejects unknown frame IDs');
assert.strictEqual(JSON.stringify(config.settingsNavigationOrder), exactBeforeInvalid,
  'invalid exact-index drag destinations leave the hierarchy unchanged');
assert.strictEqual(saveCount, 4, 'each accepted exact-index move persists once; rejected moves do not save');
assert.strictEqual('settingsTabOrder' in config, false, 'canonical hierarchical updates do not create a flat runtime compatibility mirror');

// Profile and persistence integrations use the hierarchical value as canonical.
const profiles = load('js/settings/SettingsProfiles.js', { SettingsPageRegistry: registry },
  'this.api = { expandStoredSettings, expandProfile, profileSavePathMatches, SPARSE_FORMAT };');
const legacyProfileOrder = ['weather','modules','settingsWindow','themes','dashboard','general'];
const owner = {
  profileDefaults: { settingsNavigationOrder: defaultOrder, settingsTabLabels: {}, colors: {}, weatherToken: '' },
  profileStorageFormat: 'sparse-v1', colorNames: [], profileMigrationPending: false,
  resetOverrides: {}, activeProfile: 'Work',
  normalizeSettingsNavigationOrder: value => registry.normalizeNavigationOrder(value),
  settingsNavigationOrderFromLegacyTabOrder: value => registry.navigationOrderFromLegacyTabOrder(value)
};
const expanded = profiles.api.expandStoredSettings(owner, {
  settingsPersistenceFormat: 'profile-overrides-v1',
  settingsSchemaVersion: 1,
  profileStorageFormat: 'sparse-v1',
  activeProfile: 'Work',
  profiles: { Work: { settingsTabOrder: legacyProfileOrder } },
  profileOverrides: {}
});
assert.deepStrictEqual(Array.from(expanded.settingsNavigationOrder.pagesByGroup.modules.slice(0, 2)), ['weather','modules']);
assert.deepStrictEqual(Array.from(expanded.settingsNavigationOrder.pagesByGroup.appearance), ['settingsWindow','themes','interface']);
assert.strictEqual('settingsTabOrder' in expanded.profiles.Work, false, 'legacy field is removed from migrated profile storage');
const expandedProfile = profiles.api.expandStoredSettings(owner, {
  settingsPersistenceFormat: 'profile-overrides-v1', settingsSchemaVersion: 1, profileStorageFormat: 'sparse-v1',
  activeProfile: 'Work', profiles: { Work: { settingsNavigationOrder: defaultOrder } }, profileOverrides: {}
});
assert.strictEqual('settingsTabOrder' in expandedProfile.profiles.Work, false, 'legacy order is stripped from stored profile values');
assert.strictEqual(owner.profileMigrationPending, true, 'legacy profile migration is scheduled for writeback');
const expandedProfileValue = profiles.api.expandProfile(owner, { settingsNavigationOrder: defaultOrder });
assert.strictEqual('settingsTabOrder' in expandedProfileValue, false, 'expanded profile data excludes the obsolete flat order');
assert.deepStrictEqual(Array.from(expandedProfileValue.settingsNavigationOrder.groupOrder), Array.from(defaultOrder.groupOrder));
assert.strictEqual(profiles.api.profileSavePathMatches(owner, 'settingsWindow', null, ['settingsNavigationOrder','groupOrder']), true,
  'both group and page order paths belong to the Settings Window profile scope');

// Old root-level flat order migrates into the hierarchical runtime representation;
// no flat compatibility mirror is recreated.
owner.profileMigrationPending = false;
const legacyRootExpanded = profiles.api.expandStoredSettings(owner, {
  settingsPersistenceFormat: 'profile-overrides-v1',
  settingsSchemaVersion: 1,
  profileStorageFormat: 'full',
  activeProfile: 'Legacy',
  settingsTabOrder: legacyProfileOrder,
  profiles: { Legacy: { settingsTabOrder: ['modules','weather','themes','settingsWindow'] } },
  profileOverrides: {}
});
assert.deepStrictEqual(Array.from(legacyRootExpanded.settingsNavigationOrder.pagesByGroup.modules.slice(0, 2)), ['weather','modules'],
  'legacy root order takes precedence over the old profile baseline');
assert.strictEqual('settingsTabOrder' in legacyRootExpanded.profiles.Legacy, false,
  'old flat page order is stripped from migrated full profiles');
assert.strictEqual(owner.profileMigrationPending, true, 'root/profile order migration requests a writeback');

const persistence = read('js/settings/SettingsPersistence.js');
assert(persistence.includes('settingsNavigationOrder: cloneValue(owner && typeof owner.normalizeSettingsNavigationOrder === \"function\"'),
  'profile snapshot delegates normalization to the Settings registry wrapper');
assert(!persistence.includes('settingsTabOrder: cloneValue(config.settingsTabOrder'), 'flat array is not part of profile snapshots');
assert(persistence.includes('managedKeys.indexOf("settingsTabOrder")') && persistence.includes('managedKeys.push("settingsTabOrder")'), 'legacy root field is removed on next write');
const apply = read('js/settings/SettingsApplyCore.js');
assert(apply.includes('normalizeNavigationOrderForOwner(owner, o.settingsNavigationOrder)'), 'new format is normalized by the Settings owner wrapper');
assert(apply.includes('legacyNavigationOrderForOwner(owner, o.settingsTabOrder)'), 'legacy format remains readable through the Settings owner wrapper');
const settings = read('Settings.qml');
assert(settings.includes('import \"js/settings/SettingsPageRegistry.js\" as SettingsPageRegistry'), 'Settings root imports the canonical registry');
assert(settings.includes('function settingsNavigationOrderFromLegacyTabOrder(value)'), 'Settings root exposes legacy migration wrapper');
assert(!settings.includes('function flattenSettingsNavigationOrder(value)'), 'Settings root no longer exposes the obsolete flat-order adapter');
const resets = read('js/settings/SettingsResets.js');
assert(resets.includes('"settingsNavigationOrder", "settingsTabLabels"'), 'Reset restores the hierarchical order');
assert(settings.includes('"settingsNavigationOrder", "settingsTabLabels", "animationSettings"'), 'Settings Window Reset visibility tracks the new order');
assert(controller.includes('function settingsNavigationGroupOrderNormalized()'), 'controller exposes group order separately');
assert(controller.includes('function moveSettingsNavigationGroup(id, delta)'), 'controller retains its adjacent keyboard/compatibility move API');
assert(controller.includes('function moveSettingsNavigationGroupTo(id, toIndex)'), 'controller exposes arbitrary-index group reordering for drag and drop');
assert(controller.includes('function moveSettingsTabWithinGroupTo(groupId, id, toIndex)'), 'controller exposes arbitrary-index page reordering for drag and drop');
assert(controller.includes('function moveSettingsTab(id, delta)'), 'page movement compatibility wrapper remains available');
assert(controller.includes('function moveSettingsTabWithinGroup(groupId, id, delta)'), 'explicit frame-scoped page move API is available');
assert(controller.includes('function moveSettingsTabWithinGroupTo(groupId, id, toIndex)'), 'controller exposes exact-index page movement for drag and drop');
console.log('hierarchical Settings order: defaults, normalization, legacy migration, per-group page movement, frame movement, profile scope and persistence: OK');
NODE
