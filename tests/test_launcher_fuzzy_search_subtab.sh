#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
node - "$ROOT/js/settings/SettingsPageRegistry.js" "$ROOT/components/settings/SettingsNavigationController.qml" "$ROOT/components/settings/sections/SettingsLauncherSection.qml" <<'JS'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const [registryPath, navigationPath, uiPath] = process.argv.slice(2);

const registrySource = fs.readFileSync(registryPath, 'utf8').replace(/^\.pragma library\s*/, '');
const registry = vm.runInThisContext(registrySource + '\n({ subtabsForPageId })');
assert.deepStrictEqual(Array.from(registry.subtabsForPageId('launcher')),
  ['Общее', 'Поиск', 'Вкладки', 'Проекты', 'Действия', 'Анимация', 'Приложения'],
  'Launcher gets a dedicated Search subtab immediately after General');

const navigation = fs.readFileSync(navigationPath, 'utf8');
const start = navigation.indexOf('    function settingsSubTabChangeSpec(pageId, sub) {');
const end = navigation.indexOf('\n    function settingsSubTabHasChanges', start);
assert(start >= 0 && end > start, 'Launcher subtab dirty-state map exists');
const context = {};
vm.createContext(context);
vm.runInContext(navigation.slice(start, end) + '\nthis.spec = settingsSubTabChangeSpec;', context);
const keys = index => Array.from(context.spec('launcher', index).keys);
assert(keys(0).includes('launcherWallpaperDirectory'), 'General still tracks wallpaper folder settings');
for (const key of ['launcherFuzzySearchApps', 'launcherFuzzySearchActions', 'launcherFuzzySearchSchemes', 'launcherFuzzySearchWallpapers'])
  assert(!keys(0).includes(key), `${key} is no longer dirty-tracked under General`);
assert.deepStrictEqual(keys(1), [
  'launcherFuzzySearchApps',
  'launcherFuzzySearchActions',
  'launcherFuzzySearchSchemes',
  'launcherFuzzySearchWallpapers'
], 'Search dirty indicator tracks all four fuzzy switches as one subtab');
assert.deepStrictEqual(keys(2), ['launcherTabIcons', 'launcherTabLabels', 'launcherTabOrder', 'launcherTabVisible', 'launcherCrossSearchCalculator', 'launcherCrossSearchProjects', 'launcherCrossSearchRunHistory'], 'Tabs dirty-state index shifts with the new subtab');
assert.deepStrictEqual(keys(3), ['launcherProjects'], 'Projects dirty-state index shifts');
assert.deepStrictEqual(keys(4), ['launcherCustomActions'], 'Actions dirty-state index shifts');
assert.deepStrictEqual(keys(5), ['animationLauncherMorphDuration', 'animationLauncherMorphProfile'], 'Animation dirty-state index shifts');
assert.deepStrictEqual(keys(6), ['launcherFavoriteApps', 'launcherHiddenApps'], 'Applications dirty-state index shifts');

const ui = fs.readFileSync(uiPath, 'utf8');
for (const [key, heading] of [
  ['launcherFuzzySearchApps', 'Поиск приложений'],
  ['launcherFuzzySearchActions', 'Поиск действий'],
  ['launcherFuzzySearchSchemes', 'Поиск цветовых схем'],
  ['launcherFuzzySearchWallpapers', 'Поиск обоев']
]) {
  const marker = `changeKeys: ({ keys: ["${key}"] })`;
  const position = ui.indexOf(marker);
  assert(position >= 0, `${key} settings group is present`);
  const groupStart = ui.lastIndexOf('    SettingsGroup {', position);
  const groupEndCandidate = ui.indexOf('\n    SettingsGroup {', position);
  const groupEnd = groupEndCandidate < 0 ? ui.length : groupEndCandidate;
  const group = ui.slice(groupStart, groupEnd);
  assert(group.includes('currentPageSubTabIndex === 1'), `${heading} appears only in the Search subtab`);
  assert(group.includes(`heading: "${heading}"`), `${key} retains its descriptive heading`);
}
console.log('Launcher fuzzy-search subtab: OK');
JS
