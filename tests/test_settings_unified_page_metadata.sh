#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REGISTRY="$ROOT/js/settings/SettingsPageRegistry.js"
NAV="$ROOT/components/settings/SettingsNavigationController.qml"
SEARCH="$ROOT/components/settings/SettingsSearchController.qml"

node - "$ROOT" <<'NODE'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const root = process.argv[2];
const registryPath = path.join(root, 'js/settings/SettingsPageRegistry.js');
const source = fs.readFileSync(registryPath, 'utf8').replace(/^\.pragma library\s*/, '');
const registry = {};
vm.runInNewContext(source, registry, { filename: registryPath });

const catalog = Array.from(registry.pageMetadataCatalog());
const publicTabs = Array.from(registry.tabDefinitions());
const groups = Array.from(registry.navigationGroupDefinitions());
const routeDefinitions = Array.from(registry.otherPageDefinitions());
assert.strictEqual(catalog.length, 23, 'unified catalog contains all 23 navigable pages');
assert.strictEqual(publicTabs.length, 23, 'legacy tabDefinitions API exposes the unified catalog');
assert.deepStrictEqual(catalog.map(page => page.id), publicTabs.map(page => page.id));
const defaultOrder = catalog.map(page => page.id);
const groupedOrder = Array.from(registry.groupedTabOrder(defaultOrder));
const navigationItems = Array.from(registry.navigationItemsForOrder(groupedOrder, {}));
assert.strictEqual(navigationItems.length, 23, 'sidebar model retains every navigable page');
assert.strictEqual(new Set(navigationItems.map(item => item.id)).size, 23, 'sidebar rows have unique click targets');
assert(navigationItems.every(item => item.id && item.label && item.groupId), 'every sidebar row has an ID, label and group');
const navigationCounts = Object.fromEntries(groups.map(group => [group.id, navigationItems.filter(item => item.groupId === group.id).length]));
assert.deepStrictEqual(navigationCounts, { appearance: 2, modules: 12, dashboard: 1, launcher: 7, general: 1 },
  'sidebar pages populate all five collapsible navigation groups');
const customRows = Array.from(registry.navigationItemsForOrder(['themes', 'modules', 'not-a-page'], { themes: 'My appearance' }));
assert.deepStrictEqual(customRows.map(item => [item.id, item.label, item.groupId]), [
  ['themes', 'My appearance', 'appearance'], ['modules', 'Включение модулей', 'modules']
], 'custom labels survive and unknown page IDs are excluded from clickable rows');
assert.strictEqual(new Set(catalog.map(page => page.id)).size, 23, 'page IDs stay unique');
assert.strictEqual(groups.length, 5, 'navigation groups remain complete');
assert(groups.every(group => typeof group.description === 'string' && group.description.length > 0),
  'all navigation groups have central descriptions');

const routeById = new Map(routeDefinitions.map(page => [page.id, page]));
const allSubTabIds = [];
let subTabCount = 0;
for (const page of catalog) {
  assert.ok(page.defaultLabel && page.label === page.defaultLabel, `${page.id} has a central default label`);
  assert.ok(page.groupId && page.navigationGroupLabel, `${page.id} resolves its navigation group`);
  assert.ok(page.description && page.description.length > 0, `${page.id} has a short page description`);
  assert.ok(Array.isArray(page.keywords), `${page.id} declares a keyword array for future synonyms`);
  assert.strictEqual(registry.pageMetadataForId(page.id).groupId, page.groupId, `${page.id} resolves through pageMetadataForId`);
  assert.strictEqual(registry.saveScopeForPageId(page.id, 0), page.saveScope,
    `${page.id} keeps its legacy save scope through the unified metadata`);

  const route = routeById.get(page.id);
  assert.strictEqual(page.hasSharedPageRoute, Boolean(route), `${page.id} route kind stays explicit`);
  const subtabs = Array.from(page.subTabs);
  if (route) {
    assert.strictEqual(subtabs.length, route.subTabs.length, `${page.id} metadata covers each subtab`);
    assert.deepStrictEqual(Array.from(registry.subtabsForPageId(page.id)), Array.from(route.subTabs),
      `${page.id} legacy subtab labels remain unchanged`);
  } else {
    assert.strictEqual(subtabs.length, 0, `${page.id} special page has no invented subtabs`);
  }
  for (let i = 0; i < subtabs.length; i++) {
    const subtab = subtabs[i];
    assert.strictEqual(subtab.index, i, `${page.id} subtab ${i} preserves the established index`);
    assert.strictEqual(subtab.label, route.subTabs[i], `${page.id} subtab label is preserved`);
    const expectedSlug = subtab.label.toLocaleLowerCase().replace(/ё/g, 'е').replace(/[^a-zа-я0-9]+/g, '-').replace(/^-+|-+$/g, '');
    assert.strictEqual(subtab.id, `${page.id}.${expectedSlug || `subtab-${i}`}`, `${page.id} gets a stable label-derived metadata ID`);
    assert.ok(Array.isArray(subtab.keywords), `${subtab.id} declares keyword metadata`);
    allSubTabIds.push(subtab.id);
    subTabCount++;
  }
}
assert.strictEqual(routeById.size, 21, 'all 21 shared content pages remain registered');
assert.strictEqual(subTabCount, 65, 'all existing 65 subtabs are included in the unified catalog');
assert.strictEqual(new Set(allSubTabIds).size, allSubTabIds.length, 'subtab metadata IDs are unique');
assert.strictEqual(registry.pageMetadataForId('not-a-page'), null, 'unknown pages return no metadata');
assert.strictEqual(registry.saveScopeForPageId('general', 1), '', 'General profile/storage subtabs remain unscoped');
assert.strictEqual(registry.saveScopeForPageId('themes', 0), '', 'special Themes page remains unscoped');

const navigation = fs.readFileSync(path.join(root, 'components/settings/SettingsNavigationController.qml'), 'utf8');
const search = fs.readFileSync(path.join(root, 'components/settings/SettingsSearchController.qml'), 'utf8');
assert(navigation.includes('SettingsPageRegistry.tabDefinitions()'), 'navigation consumes the unified page catalog');
assert(navigation.includes('SettingsPageRegistry.navigationItemsForOrder('), 'clickable sidebar rows come from the complete registry builder');
assert(!navigation.includes('for (var i = 0; i < order.length; ++i)\n            var metadata'), 'sidebar row builder cannot detach row creation from its loop');
assert(navigation.includes('SettingsPageRegistry.subtabsForPageId('), 'existing subtab label API stays compatible');
assert(search.includes('SettingsPageRegistry.pageMetadataForId(activePageId)'), 'search consumes page metadata by stable page ID');
assert(search.includes('pageMetadata.description'), 'search results retain the central page description');
assert(search.includes('pageDescription: pageDescription'), 'page description is available as result context');
assert(search.includes('pageMetadata.subTabs[subTabIndex]'), 'search index resolves central subtab metadata');
assert(search.includes('subTabLabel, targetKey'), 'search includes the central subtab label');
assert(!search.includes('activePageId, pageDescription, subTabLabel'), 'page descriptions do not create broad duplicate control matches');
assert(search.includes('subTabMetadata.id'), 'search results retain the stable subtab metadata ID');
console.log('settings unified metadata: 5 groups, 23 pages, 21 routes, 65 subtabs: OK');
NODE

echo 'settings unified page metadata: OK'
