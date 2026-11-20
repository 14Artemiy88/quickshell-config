#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT/js/settings/SettingsPageRegistry.js" "$ROOT/components/settings/SettingsNavigationController.qml" "$ROOT/components/settings/sections/SettingsLauncherSection.qml" <<'JS'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const [registryPath, navigationPath, sectionPath] = process.argv.slice(2);
const registrySource = fs.readFileSync(registryPath, 'utf8').replace(/^\.pragma library\s*/, '');
const registry = vm.runInThisContext(registrySource + '\n({ subtabsForPageId })');
assert.deepStrictEqual(Array.from(registry.subtabsForPageId('launcherActions')),
  ['Переходы', 'Инструменты', 'Пользовательские'],
  'built-in categories and custom actions must be peer tabs');

const navigation = fs.readFileSync(navigationPath, 'utf8');
const start = navigation.indexOf('    function settingsSubTabChangeSpec(pageId, sub) {');
const end = navigation.indexOf('\n    function settingsSubTabHasChanges', start);
assert(start >= 0 && end > start, 'subtab dirty-state mapping is available');
const context = {};
vm.createContext(context);
vm.runInContext(navigation.slice(start, end) + '\nthis.spec = settingsSubTabChangeSpec;', context);
assert.deepStrictEqual(Array.from(context.spec('launcherActions', 0).arrayContains.launcherDisabledBuiltinActions),
  ['tab.apps', 'tab.run', 'tab.windows', 'tab.clipboard', 'tab.power', 'tab.network', 'tab.packages', 'tab.pass', 'tab.projects', 'tab.calculator'],
  'transitions dirty marker tracks only the ten tab shortcuts');
assert.deepStrictEqual(Array.from(context.spec('launcherActions', 1).arrayContains.launcherDisabledBuiltinActions),
  ['tool.colorSchemes', 'tool.schemeVariants', 'tool.wallpapers', 'tool.emoji', 'tool.wallpaperDynamic'],
  'tools dirty marker tracks only the five built-in tools');
assert.deepStrictEqual(Array.from(context.spec('launcherActions', 2).keys), ['launcherCustomActions']);

const section = fs.readFileSync(sectionPath, 'utf8');
function groupAt(index) {
  const marker = 'objectName: "settings-search-page:launcherActions"';
  let pos = -1;
  for (let i = 0; i <= index; i++) pos = section.indexOf(marker, pos + 1);
  assert(pos >= 0, `Launcher Actions settings group ${index} exists`);
  const startAt = section.lastIndexOf('    SettingsGroup {', pos);
  const nextAt = section.indexOf('\n    SettingsGroup {', pos);
  return section.slice(startAt, nextAt < 0 ? section.length : nextAt);
}
for (const [index, label, subTab, model] of [
  [0, 'Переходы между вкладками', 0, 'LauncherBuiltinActions.tabActions'],
  [1, 'Инструменты', 1, 'LauncherBuiltinActions.toolActions'],
  [2, 'Пользовательские действия', 2, 'Config.launcherCustomActions']
]) {
  const block = groupAt(index);
  assert(block.includes(`currentPageSubTabIndex === ${subTab}`), `${label} routes to its own tab`);
  assert(block.includes(`settingsSearchSubTabIndex: ${subTab}`), `${label} search result opens its tab`);
  assert(block.includes(`heading: "${label}"`), `${label} has a direct page heading`);
  if (index < 2) assert(block.includes(`model: ${model}`), `${label} keeps the correct action model`);
}
const transition = groupAt(0);
const tools = groupAt(1);
assert(!/\n        SettingsGroup \{/.test(transition) && !/\n        SettingsGroup \{/.test(tools),
  'built-in content has no nested SettingsGroup frames');
console.log('Launcher Actions built-in categories are separate peer tabs without nested frames: OK');
JS
