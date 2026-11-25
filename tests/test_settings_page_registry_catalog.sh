#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REGISTRY="$ROOT/js/settings/SettingsPageRegistry.js"
COMPONENTS="$ROOT/components/settings"

node - "$REGISTRY" "$COMPONENTS" <<'NODE'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const registryPath = process.argv[2];
const componentsPath = process.argv[3];
const source = fs.readFileSync(registryPath, 'utf8').replace(/^\.pragma library\s*/, '');
const registry = {};
vm.runInNewContext(source, registry, { filename: registryPath });
const groups = registry.navigationGroupDefinitions();
const tabs = registry.tabDefinitions();
const otherPages = registry.otherPageDefinitions();
function collectQml(dir) {
  return fs.readdirSync(dir, { withFileTypes: true }).flatMap(entry => {
    const path = require('path').join(dir, entry.name);
    return entry.isDirectory() ? collectQml(path) : (entry.isFile() && entry.name.endsWith('.qml') ? [fs.readFileSync(path, 'utf8')] : []);
  }).join('\n');
}
const content = collectQml(componentsPath);

assert.strictEqual(groups.length, 5, 'Settings should keep five top-level navigation groups');
assert.strictEqual(JSON.stringify(groups.map(item => item.id)), JSON.stringify([
  'appearance', 'modules', 'dashboard', 'launcher', 'general'
]), 'top-level group IDs/order are stable');
assert.strictEqual(tabs.length, 23, 'all 23 settings pages are registered');
assert.strictEqual(otherPages.length, 21, '21 pages use the shared SettingsPageHost registry');

const groupIds = new Set(groups.map(item => item.id));
assert.strictEqual(groupIds.size, groups.length, 'navigation group IDs are unique');
const tabIds = new Set(tabs.map(item => item.id));
assert.strictEqual(tabIds.size, tabs.length, 'settings page IDs are unique');

const expectedGroupPages = {
  appearance: ['themes', 'settingsWindow'],
  modules: ['modules', 'time', 'timers', 'player', 'mopidy', 'weather', 'cava', 'cpuRam', 'network', 'volume', 'calendar', 'notifications'],
  dashboard: ['dashboard'],
  launcher: ['launcher', 'launcherSearch', 'launcherTabs', 'launcherProjects', 'launcherActions', 'launcherAnimation', 'launcherApplications'],
  general: ['general']
};
for (const groupId of Object.keys(expectedGroupPages)) {
  const actual = tabs.filter(item => item.groupId === groupId).map(item => item.id);
  assert.strictEqual(JSON.stringify(actual), JSON.stringify(expectedGroupPages[groupId]), `page mapping for ${groupId} stays complete and ordered`);
}

const expectedSharedPages = tabs.map(item => item.id).filter(id => id !== 'modules' && id !== 'themes');
assert.strictEqual(JSON.stringify(otherPages.map(item => item.id).sort()), JSON.stringify(expectedSharedPages.slice().sort()),
  'shared page metadata covers every non-special page exactly once');
assert.strictEqual(new Set(otherPages.map(item => item.id)).size, otherPages.length,
  'shared page IDs are unique');

let subTabCount = 0;
for (const page of otherPages) {
  assert.ok(typeof page.saveScope === 'string' && page.saveScope.length > 0,
    `${page.id} has an explicit save/reset scope`);
  assert.ok(Array.isArray(page.subTabs), `${page.id} declares its subtab list`);
  assert.ok(page.subTabs.every(label => typeof label === 'string' && label.trim().length > 0),
    `${page.id} has no empty subtab labels`);
  assert.strictEqual(new Set(page.subTabs).size, page.subTabs.length,
    `${page.id} subtab labels are unique`);
  subTabCount += page.subTabs.length;
  assert.ok(content.includes(`settings-search-page:${page.id}`),
    `${page.id} is attached to the settings search/navigation tree`);
  assert.strictEqual(registry.saveScopeForPageId(page.id, 0), page.saveScope,
    `${page.id} routes its first subtab to the declared save scope`);
}
assert.strictEqual(subTabCount, 65, 'all 65 registered subtabs are accounted for');
assert.ok(content.includes('settings-search-page:modules'), 'Modules special page is in search tree');
assert.ok(content.includes('settings-search-page:themes'), 'Themes special page is in search tree');
assert.strictEqual(registry.saveScopeForPageId('general', 1), '',
  'General profile/storage subtabs do not expose a scoped save/reset action');

console.log('settings page registry: 5 groups, 23 pages, 21 shared page routes, 65 subtabs: OK');
NODE

echo 'settings page registry catalogue: OK'
