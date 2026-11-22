#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { echo "Dashboard independent cards: FAIL: $*" >&2; exit 1; }

node - "$ROOT" <<'NODE'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const root = process.argv[2];
function read(relative) { return fs.readFileSync(path.join(root, relative), 'utf8'); }
function load(relative, append = '', globals = {}) {
  const source = read(relative)
    .replace(/^\.pragma library\s*$/gm, '')
    .replace(/^\.import .*$/gm, '');
  const context = { ...globals };
  vm.runInNewContext(source + '\n' + append, context, { filename: relative });
  return context;
}

// Card selection is independent state with a stable, validated set of IDs.
const cardApi = load('js/dashboard/DashboardCards.js',
  'this.api = { DEFAULT_IDS, DEFINITIONS, defaults, normalize, contains, setEnabled, normalizeOrder, indexOf, move, orderedVisible };').api;
assert.deepStrictEqual(Array.from(cardApi.defaults()), ['today', 'system', 'network', 'weather', 'media']);
assert.strictEqual(cardApi.contains(undefined, 'system'), true, 'missing/legacy setting defaults to all cards');
assert.deepStrictEqual(Array.from(cardApi.normalize(['media', 'system', 'media', 'unknown'])), ['media', 'system']);
assert.deepStrictEqual(Array.from(cardApi.normalize(['system', 'network', 'weather', 'media'])), ['system', 'network', 'weather', 'media'], 'runtime visibility preserves an explicit choice to hide Today');
assert.deepStrictEqual(Array.from(cardApi.normalize([])), [], 'empty list is a valid choice to hide all cards');
const withoutToday = cardApi.setEnabled(cardApi.defaults(), 'today', false);
assert.deepStrictEqual(Array.from(withoutToday), ['system', 'network', 'weather', 'media'], 'Today can be disabled while all four module cards remain enabled');
assert.deepStrictEqual(Array.from(cardApi.orderedVisible(cardApi.defaults(), withoutToday)).map(item => item.id),
  ['system', 'network', 'weather', 'media'], 'the Dashboard model does not re-enable Today after the checkbox is changed');
const withoutNetwork = cardApi.setEnabled(cardApi.defaults(), 'network', false);
assert.deepStrictEqual(Array.from(withoutNetwork), ['today', 'system', 'weather', 'media']);
assert.deepStrictEqual(Array.from(cardApi.setEnabled(withoutNetwork, 'network', true)), ['today', 'system', 'weather', 'media', 'network']);
assert.deepStrictEqual(Array.from(cardApi.setEnabled(withoutNetwork, 'not-a-card', true)), ['today', 'system', 'weather', 'media']);
assert.strictEqual(cardApi.DEFINITIONS.length, 5);
assert.strictEqual(cardApi.DEFINITIONS[0].id, 'today');
assert.deepStrictEqual(Array.from(cardApi.normalizeOrder(undefined)), ['today', 'system', 'network', 'weather', 'media']);
assert.deepStrictEqual(Array.from(cardApi.normalizeOrder(['media', 'system', 'media', 'bad'])), ['media', 'system', 'today', 'network', 'weather']);
assert.deepStrictEqual(Array.from(cardApi.move(cardApi.defaults(), 'weather', -1)), ['today', 'system', 'weather', 'network', 'media']);
assert.deepStrictEqual(Array.from(cardApi.move(['media', 'system', 'today', 'network', 'weather'], 'media', -1)), ['media', 'system', 'today', 'network', 'weather'], 'first card cannot move higher');
assert.deepStrictEqual(Array.from(cardApi.move(['media', 'system', 'today', 'network', 'weather'], 'weather', 1)), ['media', 'system', 'today', 'network', 'weather'], 'last card cannot move lower');
assert.deepStrictEqual(Array.from(cardApi.orderedVisible(['media', 'weather', 'system', 'network'], ['network', 'media'])).map(item => item.id), ['media', 'network'], 'visibility filtering retains the configured order');
assert.deepStrictEqual(Array.from(cardApi.orderedVisible(['media', 'weather', 'system', 'network'], [])).map(item => item.id), [], 'no visible cards gives an empty Dashboard');

const config = read('Config.qml');
const defaults = read('js/settings/SettingsDefaults.js');
const pageSection = read('components/settings/sections/SettingsDashboardSection.qml');
const dashboard = read('components/Dashboard.qml');
const pageContent = read('components/settings/SettingsPageContent.qml');
assert.match(config, /property var dashboardVisibleCards: \["today", "system", "network", "weather", "media"\]/);
assert.match(config, /property var dashboardCardOrder: \["today", "system", "network", "weather", "media"\]/);
assert.match(defaults, /dashboardVisibleCards: \["today", "system", "network", "weather", "media"\]/);
assert.match(defaults, /dashboardCardOrder: \["today", "system", "network", "weather", "media"\]/);
assert.match(pageSection, /heading: "Карточки Dashboard"/);
assert.match(pageSection, /независимо от включения соответствующих модулей/);
assert.match(pageSection, /DashboardCards\.move\(Config\.dashboardCardOrder, id, direction\)/, 'settings expose independent card reordering');
assert.match(pageSection, /MoveArrowButton/, 'card rows expose up/down ordering controls');
assert.strictEqual((pageSection.match(/onToggled: root\.setCardEnabled\(/g) || []).length, 1, 'one repeated checkbox delegate controls independent card visibility');
assert.match(pageSection, /root\.settings\.save\(\)/, 'visibility and order are saved');
assert.match(dashboard, /property var orderedCards: DashboardCards\.orderedVisible\(Config\.dashboardCardOrder, Config\.dashboardVisibleCards\)/, 'Dashboard card model uses saved order and independent visibility');
assert.match(dashboard, /model: cards\.columnSplit\.left[\s\S]*?model: cards\.columnSplit\.right/, 'balanced column stacks render every visible card');
assert.match(dashboard, /delegate: InfoCard/, 'ordered Dashboard cards are rendered through the shared InfoCard delegate');
assert.match(dashboard, /Карточки не выбраны/);
assert.match(pageContent, /SettingsDashboardSection/);
assert.match(pageSection, /host.currentPageId === "dashboard"/);
assert.doesNotMatch(dashboard, /Settings\.(?:cpu|networkStat|weatherNow|player)\s*\?\s*root\.isCardEnabled/, 'module enable flags must not drive card visibility');
assert.doesNotMatch(dashboard, /Process\s*\{/, 'Dashboard cards must reuse existing shared models');

// Dashboard page is independently discoverable in Settings navigation.
const registry = load('js/settings/SettingsPageRegistry.js',
  'this.api = { hasOtherPageId, pageForId, saveScopeForPageId, navigationGroupIdForTabId };').api;
assert.strictEqual(registry.hasOtherPageId('dashboard'), true);
assert.strictEqual(registry.saveScopeForPageId('dashboard', 0), 'dashboard');
assert.strictEqual(registry.navigationGroupIdForTabId('dashboard'), 'dashboard');
const navController = read('components/settings/SettingsNavigationController.qml');
assert.match(navController, /dashboard: "dashboard"/);
assert.match(navController, /case "dashboard": settings\.resetDashboardSettings\(\); break/);
const settingsQml = read('Settings.qml');
assert.match(settingsQml, /if \(scope === "dashboard"\)\s+return hasAny\(\["dashboardVisibleCards", "dashboardCardOrder", "dashboardColumnsMode", "dashboardCardSizes"\]\)/);
assert.match(settingsQml, /function resetDashboardSettings\(\)\s*\{\s*SettingsResets\.resetDashboardSettings\(root, Config\)/);

// Persistence includes its own field and profile-scoped saving only touches this field.
const persistence = load('js/settings/SettingsPersistence.js',
  'this.api = { snapshotObject, normalizeDashboardCards, normalizeDashboardCardOrder };').api;
const configSnapshot = { dashboardVisibleCards: ['media', 'weather'], dashboardCardOrder: ['media', 'system', 'network', 'weather'] };
const snapshot = persistence.snapshotObject({ moduleNames: [], colorNames: [], weatherToken: '' }, configSnapshot);
assert.deepStrictEqual(Array.from(snapshot.dashboardVisibleCards), ['media', 'weather']);
assert.deepStrictEqual(Array.from(snapshot.dashboardCardOrder), ['media', 'system', 'network', 'weather', 'today']);
const todayOffSnapshot = persistence.snapshotObject({ moduleNames: [], colorNames: [], weatherToken: '' }, {
  dashboardVisibleCards: ['system', 'network', 'weather', 'media'],
  dashboardCardOrder: ['today', 'system', 'network', 'weather', 'media']
});
assert.deepStrictEqual(Array.from(todayOffSnapshot.dashboardVisibleCards), ['system', 'network', 'weather', 'media'],
  'saving a current profile does not re-enable Today after the user disables it');
assert.deepStrictEqual(Array.from(persistence.normalizeDashboardCards(['weather', 'invalid', 'weather'])), ['weather']);
assert.deepStrictEqual(Array.from(persistence.normalizeDashboardCards(['system', 'network', 'weather', 'media'], ['system', 'network', 'weather', 'media'])), ['today', 'system', 'network', 'weather', 'media'], 'persisted legacy defaults migrate to Today when their order also predates Today');
assert.deepStrictEqual(Array.from(persistence.normalizeDashboardCards(['system', 'network', 'weather', 'media'], ['today', 'system', 'network', 'weather', 'media'])), ['system', 'network', 'weather', 'media'], 'a current five-card order preserves an explicit choice to disable Today');
const profiles = load('js/settings/SettingsProfiles.js',
  'this.api = { profileSavePathMatches };').api;
assert.strictEqual(profiles.profileSavePathMatches({}, 'dashboard', null, ['dashboardVisibleCards']), true);
assert.strictEqual(profiles.profileSavePathMatches({}, 'dashboard', null, ['dashboardCardOrder']), true, 'card order is saved in Dashboard-scoped profiles');
assert.strictEqual(profiles.profileSavePathMatches({}, 'dashboard', null, ['dashboardColumnsMode']), true, 'grid mode is saved in Dashboard-scoped profiles');
assert.strictEqual(profiles.profileSavePathMatches({}, 'dashboard', null, ['launcherWidth']), false);

const applySystem = load('js/settings/SettingsApplySystemVisual.js',
  'this.api = { apply };').api;
const appliedConfig = {};
applySystem.apply(appliedConfig, { dashboardVisibleCards: ['media', 'invalid', 'media'], dashboardCardOrder: ['weather', 'weather', 'media'] });
assert.deepStrictEqual(Array.from(appliedConfig.dashboardVisibleCards), ['media'], 'saved dashboard card choices are normalized on apply');
assert.deepStrictEqual(Array.from(appliedConfig.dashboardCardOrder), ['weather', 'media', 'today', 'system', 'network'], 'saved card order is normalized and filled with missing cards');
const legacyVisibleConfig = {};
applySystem.apply(legacyVisibleConfig, { dashboardVisibleCards: ['system', 'network', 'weather', 'media'], dashboardCardOrder: ['system', 'network', 'weather', 'media'] });
assert.deepStrictEqual(Array.from(legacyVisibleConfig.dashboardVisibleCards), ['today', 'system', 'network', 'weather', 'media'], 'the previous all-cards default is upgraded when both stored arrays predate Today');
const intentionallyHiddenToday = {};
applySystem.apply(intentionallyHiddenToday, { dashboardVisibleCards: ['system', 'network', 'weather', 'media'], dashboardCardOrder: ['today', 'system', 'network', 'weather', 'media'] });
assert.deepStrictEqual(Array.from(intentionallyHiddenToday.dashboardVisibleCards), ['system', 'network', 'weather', 'media'], 'loading a current profile preserves Today being disabled');
const applyLegacyConfig = { dashboardCardOrder: ['media', 'network', 'weather', 'system'] };
applySystem.apply(applyLegacyConfig, {});
assert.deepStrictEqual(Array.from(applyLegacyConfig.dashboardCardOrder), ['today', 'system', 'network', 'weather', 'media'], 'profiles without an order key restore defaults instead of inheriting a previous profile');
const resets = load('js/settings/SettingsResets.js',
  'this.api = { resetDashboardSettings };').api;
const resetConfig = { dashboardVisibleCards: [], dashboardCardOrder: ['media', 'weather', 'network', 'system'] };
let resetSaveCount = 0;
const resetOwner = {
  activeProfile: 'Compact', profiles: { Compact: {} },
  expandedProfileData: () => ({ dashboardVisibleCards: ['weather', 'media'], dashboardCardOrder: ['media', 'network', 'system', 'weather'] }),
  defaultConfig: { dashboardVisibleCards: ['today', 'system', 'network', 'weather', 'media'], dashboardCardOrder: ['today', 'system', 'network', 'weather', 'media'] },
  save: () => { resetSaveCount++; }, resetUnavailable: () => {}
};
resets.resetDashboardSettings(resetOwner, resetConfig);
assert.deepStrictEqual(Array.from(resetConfig.dashboardVisibleCards), ['weather', 'media'], 'reset restores the active profile card selection');
assert.deepStrictEqual(Array.from(resetConfig.dashboardCardOrder), ['media', 'network', 'system', 'weather', 'today'], 'reset preserves an older profile order and appends the new card');
assert.strictEqual(resetSaveCount, 1, 'reset persists the active-profile card selection');
resetOwner.expandedProfileData = () => ({ dashboardVisibleCards: ['system', 'network', 'weather', 'media'], dashboardCardOrder: ['system', 'network', 'weather', 'media'] });
resets.resetDashboardSettings(resetOwner, resetConfig);
assert.deepStrictEqual(Array.from(resetConfig.dashboardVisibleCards), ['today', 'system', 'network', 'weather', 'media'], 'reset migrates the former default card selection when its order predates Today');
resetOwner.expandedProfileData = () => ({ dashboardVisibleCards: ['system', 'network', 'weather', 'media'] });
resets.resetDashboardSettings(resetOwner, resetConfig);
assert.deepStrictEqual(Array.from(resetConfig.dashboardVisibleCards), ['today', 'system', 'network', 'weather', 'media'], 'reset migrates the former default when an older profile has no card-order field');
resetOwner.expandedProfileData = () => ({ dashboardVisibleCards: ['system', 'network', 'weather', 'media'], dashboardCardOrder: ['today', 'system', 'network', 'weather', 'media'] });
resets.resetDashboardSettings(resetOwner, resetConfig);
assert.deepStrictEqual(Array.from(resetConfig.dashboardVisibleCards), ['system', 'network', 'weather', 'media'], 'reset preserves an intentionally disabled Today card in a current profile');
resetOwner.expandedProfileData = () => ({});
resets.resetDashboardSettings(resetOwner, resetConfig);
assert.deepStrictEqual(Array.from(resetConfig.dashboardVisibleCards), ['today', 'system', 'network', 'weather', 'media'], 'legacy profiles fall back to all dashboard cards');
assert.deepStrictEqual(Array.from(resetConfig.dashboardCardOrder), ['today', 'system', 'network', 'weather', 'media'], 'legacy profiles fall back to default card order');

const persistenceSource = read('js/settings/SettingsPersistence.js');
const applySource = read('js/settings/SettingsApplySystemVisual.js');
const resetSource = read('js/settings/SettingsResets.js');
assert.match(persistenceSource, /dashboardVisibleCards: normalizeDashboardCards\(config\.dashboardVisibleCards, config\.dashboardCardOrder\)/);
assert.match(persistenceSource, /dashboardCardOrder: normalizeDashboardCardOrder\(config\.dashboardCardOrder\)/);
assert.match(applySource, /Config\.dashboardVisibleCards = normalizeDashboardCards\(o\.dashboardVisibleCards, o\.dashboardCardOrder\)/);
assert.match(applySource, /Config\.dashboardCardOrder = normalizeDashboardCardOrder\(o\.dashboardCardOrder\)/);
assert.match(resetSource, /function resetDashboardSettings\(owner, config\)/);
console.log('Dashboard independent cards/order, defaults, Settings routing, profile scope, and shared-data architecture: OK');
NODE

echo 'dashboard independent cards: OK'
