#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'NODE'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const root = process.argv[2];
function read(relative) { return fs.readFileSync(path.join(root, relative), 'utf8'); }
function load(relative, append = '', globals = {}) {
  const source = read(relative).replace(/^\.pragma library\s*$/gm, '').replace(/^\.import .*$/gm, '');
  const context = { ...globals };
  vm.runInNewContext(source + '\n' + append, context, { filename: relative });
  return context;
}

const cards = load('js/dashboard/DashboardCards.js',
  'this.api = { COLUMN_MODES, normalizeColumnsMode, columnsForWidth };').api;
assert.deepStrictEqual(Array.from(cards.COLUMN_MODES), ['auto', 'one', 'two']);
assert.strictEqual(cards.normalizeColumnsMode(undefined), 'auto');
assert.strictEqual(cards.normalizeColumnsMode('invalid'), 'auto');
assert.strictEqual(cards.normalizeColumnsMode('one'), 'one');
assert.strictEqual(cards.normalizeColumnsMode('two'), 'two');
assert.strictEqual(cards.columnsForWidth('auto', 499), 1, 'auto keeps one column below the established width threshold');
assert.strictEqual(cards.columnsForWidth('auto', 500), 2, 'auto keeps the established two-column threshold');
assert.strictEqual(cards.columnsForWidth('one', 900), 1, 'one-column mode stays one column on wide screens');
assert.strictEqual(cards.columnsForWidth('two', 520), 2, 'two-column mode uses two columns when there is room');
assert.strictEqual(cards.columnsForWidth('two', 359), 1, 'two-column mode falls back to one on narrow screens');

const config = read('Config.qml');
const defaults = read('js/settings/SettingsDefaults.js');
const settingsPage = read('components/settings/sections/SettingsDashboardSection.qml');
const dashboard = read('components/Dashboard.qml');
assert.match(config, /property string dashboardColumnsMode: "auto"/);
assert.match(defaults, /dashboardColumnsMode: "auto"/);
assert.match(settingsPage, /label: "Количество колонок"/);
assert.match(settingsPage, /model: \["Автоматически", "1 колонка", "2 колонки"\]/);
assert.match(settingsPage, /Config\.dashboardColumnsMode = normalized/);
assert.match(settingsPage, /settingsSearchId: "dashboard-columns-mode"/);
assert.match(settingsPage, /dashboardColumnsMode", "dashboardCardSizes"\]\s*\}\)/);
assert.match(dashboard, /DashboardCards\.resolveDashboardLayout\([\s\S]*?orderedCards, Config\.dashboardColumnsMode, width,[\s\S]*?Config\.dashboardCardSizes, DashboardCards\.COLUMN_GAP/);
assert.match(dashboard, /property bool useTwoColumns: layoutState\.columns === 2/);
assert.match(dashboard, /property var columnSplit: \(\{ left: layoutState\.left, right: layoutState\.right \}\)/, 'two-column stacks use the resolver and remain mutually exclusive with horizontal Bento models');
assert.match(dashboard, /id: leftColumn[\s\S]*?id: rightColumn/, 'two-column layout uses independent vertical column containers');
assert.doesNotMatch(dashboard, /GridLayout \{\s*id: cards/, 'card rows must not share GridLayout row heights');

const persistence = load('js/settings/SettingsPersistence.js',
  'this.api = { snapshotObject, normalizeDashboardColumnsMode };').api;
assert.strictEqual(persistence.normalizeDashboardColumnsMode('two'), 'two');
assert.strictEqual(persistence.normalizeDashboardColumnsMode('unexpected'), 'auto');
const snapshot = persistence.snapshotObject({ moduleNames: [], colorNames: [], weatherToken: '' }, {
  dashboardVisibleCards: ['system'],
  dashboardCardOrder: ['media', 'system', 'network', 'weather'],
  dashboardColumnsMode: 'two'
});
assert.strictEqual(snapshot.dashboardColumnsMode, 'two', 'column mode is persisted in profile snapshots');

const profiles = load('js/settings/SettingsProfiles.js', 'this.api = { profileSavePathMatches };').api;
assert.strictEqual(profiles.profileSavePathMatches({}, 'dashboard', null, ['dashboardColumnsMode']), true,
  'column mode belongs to the independent Dashboard profile scope');

const apply = load('js/settings/SettingsApplySystemVisual.js', 'this.api = { apply, normalizeDashboardColumnsMode };').api;
const applied = {};
apply.apply(applied, { dashboardColumnsMode: 'one' });
assert.strictEqual(applied.dashboardColumnsMode, 'one', 'profile apply restores selected columns mode');
const legacyApplied = {};
apply.apply(legacyApplied, {});
assert.strictEqual(legacyApplied.dashboardColumnsMode, 'auto', 'legacy profiles default to responsive auto mode');

const resets = load('js/settings/SettingsResets.js', 'this.api = { resetDashboardSettings };').api;
const resetConfig = { dashboardVisibleCards: [], dashboardCardOrder: ['media', 'weather', 'network', 'system'], dashboardColumnsMode: 'two' };
let saved = 0;
const resetOwner = {
  activeProfile: 'Compact',
  profiles: { Compact: {} },
  expandedProfileData: () => ({ dashboardVisibleCards: ['system'], dashboardCardOrder: ['system', 'network', 'weather', 'media'], dashboardColumnsMode: 'one' }),
  defaultConfig: { dashboardVisibleCards: ['system', 'network', 'weather', 'media'], dashboardCardOrder: ['system', 'network', 'weather', 'media'], dashboardColumnsMode: 'auto' },
  save: () => saved++,
  resetUnavailable: () => {}
};
resets.resetDashboardSettings(resetOwner, resetConfig);
assert.strictEqual(resetConfig.dashboardColumnsMode, 'one', 'reset restores the active profile column mode');
assert.strictEqual(saved, 1);
const legacyReset = { dashboardColumnsMode: 'two' };
resetOwner.expandedProfileData = () => ({ dashboardVisibleCards: [], dashboardCardOrder: [] });
resets.resetDashboardSettings(resetOwner, legacyReset);
assert.strictEqual(legacyReset.dashboardColumnsMode, 'auto', 'legacy profile reset restores auto mode');

const settingsQml = read('Settings.qml');
assert.match(settingsQml, /hasAny\(\["dashboardVisibleCards", "dashboardCardOrder", "dashboardColumnsMode", "dashboardCardSizes"\]\)/,
  'Dashboard dirty/reset indicators include column mode');
console.log('Dashboard columns preference, responsive layout, profiles, reset and settings search: OK');
NODE
