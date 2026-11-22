#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
node - "$ROOT/js/settings/SettingsPageRegistry.js" "$ROOT/components/settings/SettingsNavigationController.qml" "$ROOT/components/settings/sections/SettingsLauncherSection.qml" <<'JS'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const [registryPath, navigationPath, uiPath] = process.argv.slice(2);
const registrySource = fs.readFileSync(registryPath, 'utf8').replace(/^\.pragma library\s*/, '');
const registry = vm.runInThisContext(registrySource + '\n({ tabDefinitions, otherPageDefinitions, subtabsForPageId, navigationGroupIdForTabId })');
const pages = Array.from(registry.tabDefinitions());
for (const pageId of ['launcher', 'launcherSearch', 'launcherTabs', 'launcherProjects', 'launcherActions', 'launcherAnimation', 'launcherApplications']) {
  const page = pages.find(item => item.id === pageId);
  assert(page, `${pageId} is a navigable page`);
  assert.strictEqual(registry.navigationGroupIdForTabId(pageId), 'launcher', `${pageId} belongs to the Launcher folder`);
}
assert.deepStrictEqual(Array.from(registry.subtabsForPageId('launcher')), ['Общее', 'Навигация', 'Оформление', 'Поиск']);
assert.deepStrictEqual(Array.from(registry.subtabsForPageId('launcherSearch')), ['Приложения', 'Действия', 'Схемы', 'Обои']);
assert.deepStrictEqual(Array.from(registry.subtabsForPageId('launcherActions')), ['Переходы', 'Инструменты', 'Пользовательские']);
for (const pageId of ['launcherTabs', 'launcherProjects', 'launcherAnimation', 'launcherApplications'])
  assert.deepStrictEqual(Array.from(registry.subtabsForPageId(pageId)), [], `${pageId} is a direct page`);

const navigation = fs.readFileSync(navigationPath, 'utf8');
const start = navigation.indexOf('    function settingsSubTabChangeSpec(pageId, sub) {');
const end = navigation.indexOf('\n    function settingsSubTabHasChanges', start);
assert(start >= 0 && end > start, 'Launcher subtab dirty-state map exists');
const context = {};
vm.createContext(context);
vm.runInContext(navigation.slice(start, end) + '\nthis.spec = settingsSubTabChangeSpec;', context);
const keys = (page, index) => Array.from(context.spec(page, index).keys);
assert.deepStrictEqual(keys('launcher', 0), ['launcherDefaultMode', 'launcherShowResultCount']);
assert.deepStrictEqual(keys('launcher', 1), ['launcherVimKeybinds', 'launcherShowNavigationHints', 'launcherNavigationHintsHeight', 'launcherNavigationHintsFontSize', 'launcherNavigationHintsTextY']);
assert(keys('launcher', 2).includes('launcherRadius'), 'appearance controls belong to the appearance subtab');
assert.deepStrictEqual(keys('launcher', 3), ['launcherCrossSearchCalculator', 'launcherCrossSearchProjects', 'launcherCrossSearchRunHistory']);
assert.deepStrictEqual(keys('launcherSearch', 0), ['launcherFuzzySearchApps']);
assert.deepStrictEqual(keys('launcherSearch', 1), ['launcherFuzzySearchActions']);
assert.deepStrictEqual(keys('launcherSearch', 2), ['launcherFuzzySearchSchemes', 'launcherDynamicSchemeVariant']);
assert.deepStrictEqual(keys('launcherSearch', 3), ['launcherFuzzySearchWallpapers', 'launcherWallpaperDirectory']);
assert.deepStrictEqual(Array.from(context.spec('launcherActions', 0).arrayContains.launcherDisabledBuiltinActions), ['tab.apps', 'tab.run', 'tab.windows', 'tab.clipboard', 'tab.power', 'tab.network', 'tab.packages', 'tab.pass', 'tab.projects', 'tab.calculator']);
assert.deepStrictEqual(Array.from(context.spec('launcherActions', 1).arrayContains.launcherDisabledBuiltinActions), ['tool.colorSchemes', 'tool.schemeVariants', 'tool.wallpapers', 'tool.emoji', 'tool.wallpaperDynamic', 'tool.dashboard']);
assert.deepStrictEqual(keys('launcherActions', 2), ['launcherCustomActions']);

const ui = fs.readFileSync(uiPath, 'utf8');
for (const [key, heading, sub] of [
  ['launcherFuzzySearchApps', 'Поиск приложений', 0],
  ['launcherFuzzySearchActions', 'Поиск действий', 1],
  ['launcherFuzzySearchSchemes', 'Поиск цветовых схем', 2],
  ['launcherFuzzySearchWallpapers', 'Поиск обоев', 3]
]) {
  const marker = `changeKeys: ({ keys: ["${key}"] })`;
  const position = ui.indexOf(marker);
  assert(position >= 0, `${key} setting frame exists`);
  const frameStart = ui.lastIndexOf('    SettingsGroup {', position);
  const frameEndCandidate = ui.indexOf('\n    SettingsGroup {', position);
  const frame = ui.slice(frameStart, frameEndCandidate < 0 ? ui.length : frameEndCandidate);
  assert(frame.includes(`currentPageId === "launcherSearch" && root.host.currentPageSubTabIndex === ${sub}`), `${heading} is routed to its own Search page subtab`);
  assert(frame.includes(`heading: "${heading}"`));
}
console.log('Launcher settings folder, page IDs, subtabs and dirty-state routing: OK');
JS
