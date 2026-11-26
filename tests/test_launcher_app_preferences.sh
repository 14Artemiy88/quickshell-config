#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MODULE="$ROOT/js/launcher/LauncherAppPreferences.js"
APP_MODEL="$ROOT/components/launcher/models/AppModel.qml"
SECTION="$ROOT/components/settings/sections/SettingsLauncherSection.qml"
CONFIG="$ROOT/Config.qml"
DEFAULTS="$ROOT/js/settings/SettingsDefaults.js"
APPLY="$ROOT/js/settings/SettingsApplySystemVisual.js"
PERSIST="$ROOT/js/settings/SettingsPersistence.js"
RESETS="$ROOT/js/settings/SettingsResets.js"
REGISTRY="$ROOT/js/settings/SettingsPageRegistry.js"
SEARCH_PRIMITIVE="$ROOT/js/launcher/LauncherAppSearch.js"

node - "$MODULE" <<'JS'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const source = fs.readFileSync(process.argv[2], 'utf8').replace(/^\.pragma library\s*/, '');
const api = vm.runInThisContext(source + '\n({ valuesOf, normalizeIds, containsId, setId, indexOfId })');

assert.deepStrictEqual(api.normalizeIds(['org.a.desktop', ' org.b.desktop ', 'org.a.desktop', '', null]),
  ['org.a.desktop', 'org.b.desktop'], 'IDs are trimmed, deduplicated and empty values are removed');
assert.deepStrictEqual(api.normalizeIds({ 0: 'a.desktop', 1: 'b.desktop', length: 2 }),
  ['a.desktop', 'b.desktop'], 'Qt-style list values are supported');
assert.deepStrictEqual(api.normalizeIds('org.mozilla.firefox;Telegram; org.kde.dolphin '),
  ['org.mozilla.firefox', 'Telegram', 'org.kde.dolphin'], 'persisted semicolon-separated IDs are parsed as tokens, never characters');
assert.deepStrictEqual(api.normalizeIds('one.desktop,two.desktop\nthree.desktop'),
  ['one.desktop', 'two.desktop', 'three.desktop'], 'comma/newline separated persisted IDs are supported');
assert.deepStrictEqual(api.setId('org.mozilla.firefox;org.kde.dolphin', 'org.mozilla.firefox', false),
  ['org.kde.dolphin'], 'toggling a string-backed DND rule preserves the other complete IDs');
assert(api.containsId(['a.desktop'], 'a.desktop'), 'membership uses the desktop-entry ID');
assert.strictEqual(api.containsId(['a.desktop'], 'b.desktop'), false);
assert.deepStrictEqual(api.setId(['a.desktop'], 'b.desktop', true), ['a.desktop', 'b.desktop']);
assert.deepStrictEqual(api.setId(['a.desktop', 'b.desktop'], 'a.desktop', false), ['b.desktop']);
assert.strictEqual(api.indexOfId(['b.desktop', 'a.desktop'], 'a.desktop'), 1,
  'favorite ordering is retained in the stored array');
JS

node - "$CONFIG" "$DEFAULTS" "$APPLY" "$PERSIST" "$RESETS" "$REGISTRY" "$APP_MODEL" "$SECTION" "$SEARCH_PRIMITIVE" <<'JS'
const fs = require('fs');
const assert = require('assert');
const [config, defaults, apply, persist, resets, registry, model, section, searchPrimitive] = process.argv.slice(2).map(p => fs.readFileSync(p, 'utf8'));
for (const [name, source] of [['Config', config], ['defaults', defaults]]) {
  assert(source.includes('launcherFavoriteApps: []') || source.includes('property var launcherFavoriteApps: []'), `${name} has a favorites default`);
  assert(source.includes('launcherHiddenApps: []') || source.includes('property var launcherHiddenApps: []'), `${name} has a hidden apps default`);
}
assert(apply.includes('LauncherAppPreferences.normalizeIds(o.launcherFavoriteApps)'));
assert(apply.includes('LauncherAppPreferences.normalizeIds(o.launcherHiddenApps)'));
assert(persist.includes('launcherFavoriteApps: JSON.parse(JSON.stringify(config.launcherFavoriteApps || []))'));
assert(persist.includes('launcherHiddenApps: JSON.parse(JSON.stringify(config.launcherHiddenApps || []))'));
assert(resets.includes('"launcherFavoriteApps", "launcherHiddenApps"'), 'both arrays participate in Launcher reset');
assert(resets.includes('if (profile.launcherFavoriteApps === undefined) config.launcherFavoriteApps = []'));
assert(resets.includes('if (profile.launcherHiddenApps === undefined) config.launcherHiddenApps = []'));
assert(registry.includes('"Приложения"'), 'Launcher has a dedicated applications settings subtab');
assert(model.includes('import \"../../../\"'), 'AppModel imports the root QML module that declares the Config singleton');
const path = require('path');
const rootQmldir = path.resolve(path.dirname(process.argv[8]), '../../../qmldir');
assert(fs.readFileSync(rootQmldir, 'utf8').includes('singleton Config 1.0 Config.qml'), 'the root QML module exposes Config as a singleton');
assert(searchPrimitive.includes('hidden.indexOf(id) >= 0'), 'hidden apps are excluded from all Apps results by the shared primitive');
assert(model.includes('DesktopEntries.applications.values || []'), 'Launcher passes the live DesktopEntries ObjectModel values directly');
assert(!model.includes('desktopEntriesSnapshot') && !model.includes('catalogRefreshTimer') && !searchPrimitive.includes('desktopEntriesSnapshot'), 'Launcher does not cache a potentially stale desktop-entry snapshot');
assert(searchPrimitive.includes('favoriteIndex: favoriteIndex'), 'favorite IDs are used to rank applications');
assert(searchPrimitive.includes('Math.max(Number(emptyQueryLimit) || 0, favoriteCount)'), 'all favorites can appear beyond the default recent-app limit');
const querySort = searchPrimitive.slice(searchPrimitive.lastIndexOf('ranked.sort(function(a, b) {'));
assert(querySort.indexOf('if (aFavorite !== bFavorite)') >= 0 && querySort.indexOf('if (aFavorite !== bFavorite)') < querySort.indexOf('if (b.score !== a.score)'), 'favorite matches stay pinned before other search results');
assert(section.includes('Избранные и скрытые приложения'));
assert(section.includes('if (!needle && !isFavorite && !isHidden) continue'), 'settings keep the compact behavior: show no unconfigured app rows until the user searches');
assert(section.includes('Пока нет выбранных приложений.'), 'settings explain that an empty search intentionally hides unconfigured apps');
assert(section.includes('root.setLauncherAppPreference("favorite", modelData.id, checked)'));
assert(section.includes('root.setLauncherAppPreference("hidden", modelData.id, checked)'));
assert(section.includes('if (enabled) hidden = LauncherAppPreferences.setId(hidden, appId, false)'), 'favorite and hidden states are mutually exclusive');
const nav = fs.readFileSync(process.argv[2].replace(/Config\.qml$/, 'components/settings/SettingsNavigationController.qml'), 'utf8');
const start = nav.indexOf('    function settingsSubTabChangeSpec(pageId, sub) {');
const end = nav.indexOf('\n    function settingsSubTabHasChanges', start);
assert(start >= 0 && end > start, 'extract launcher subtab dirty-state mapping');
const vm = require('vm');
const context = {};
vm.createContext(context);
vm.runInContext(nav.slice(start, end).trim() + '\nthis.spec = settingsSubTabChangeSpec;', context);
assert.deepStrictEqual(Array.from(context.spec('launcherSearch', 0).keys), ['launcherFuzzySearchApps'], 'Apps search has its own dirty state');
assert.deepStrictEqual(Array.from(context.spec('launcherActions', 2).keys), ['launcherCustomActions'], 'custom actions have their own dirty state');
const pageScopes = nav.slice(nav.indexOf('function settingsTabHasChanges'), nav.indexOf('function selectSettingsTab'));
assert(pageScopes.includes('return root.launcherPageHasChanges(pageId)'), 'Launcher sidebar dirty markers use page-local selectors');
for (const id of ['launcherApplications', 'launcherAnimation', 'launcherTabs', 'launcherProjects']) assert(!pageScopes.includes(`${id}: \"launcher\"`), `${id} no longer inherits the shared Launcher dirty scope`);
assert(section.includes('objectName: \"settings-search-page:launcherApplications\"') && section.includes('currentPageId === \"launcherApplications\"'), 'favorites and hidden apps live on their own folder child page');
JS
printf 'Launcher app preferences: OK\n'
