#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'JS'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const base = process.argv[2];
const source = fs.readFileSync(path.join(base, 'components/settings/SettingsNavigationController.qml'), 'utf8');
function body(name, nextName) {
  const start = source.indexOf(`    function ${name}(`);
  const end = source.indexOf(`\n    function ${nextName}(`, start);
  assert(start >= 0 && end > start, `extract ${name}`);
  return source.slice(start, end).trim();
}
const context = {};
vm.createContext(context);
const overrides = {};
const settings = {
  hasResetChanges(scope, spec) {
    if (scope !== 'keys') return false;
    if ((spec.keys || []).some(key => Object.prototype.hasOwnProperty.call(overrides, key))) return true;
    const arrays = spec.arrayContains || {};
    for (const key of Object.keys(arrays)) {
      const values = Array.isArray(overrides[key]) ? overrides[key] : [];
      if (values.some(value => arrays[key].includes(String(value)))) return true;
    }
    return false;
  }
};
context.root = { host: { profileController: { hasActiveProfile: true } }, settings };
context.settings = settings;
vm.runInContext(body('settingsSubTabChangeSpec', 'settingsSubTabHasChanges') + '\nthis.settingsSubTabChangeSpec = settingsSubTabChangeSpec;', context);
context.root.settingsSubTabChangeSpec = context.settingsSubTabChangeSpec;
vm.runInContext(body('launcherPageHasChanges', 'settingsTabHasChanges') + '\nthis.launcherPageHasChanges = launcherPageHasChanges;', context);
context.root.launcherPageHasChanges = context.launcherPageHasChanges;
vm.runInContext(body('settingsTabHasChanges', 'selectSettingsTab') + '\nthis.settingsTabHasChanges = settingsTabHasChanges;', context);
function dirty(id) { return context.settingsTabHasChanges.call(context.root, id); }
function set(value) { for (const key of Object.keys(overrides)) delete overrides[key]; Object.assign(overrides, value); }
const launcherPages = ['launcher', 'launcherSearch', 'launcherTabs', 'launcherProjects', 'launcherActions', 'launcherAnimation', 'launcherApplications'];
function only(expected, value, label) {
  set(value);
  const actual = launcherPages.filter(dirty);
  assert.deepStrictEqual(actual, [expected], `${label}: only ${expected} should light, got ${actual.join(', ')}`);
}
only('launcher', { launcherNavigationHintsHeight: 32 }, 'navigation hints affect General only');
only('launcherSearch', { launcherFuzzySearchActions: false }, 'action fuzzy-search affects Search only');
only('launcherTabs', { launcherTabOrder: [1, 0] }, 'tab order affects Tabs only');
only('launcherProjects', { launcherProjects: [{ name: 'Demo' }] }, 'project list affects Projects only');
only('launcherActions', { launcherDisabledBuiltinActions: ['tool.emoji'] }, 'built-in action visibility affects Actions only');
only('launcherActions', { launcherCustomActions: [{ name: 'Demo', command: 'true' }] }, 'custom actions affect Actions only');
only('launcherAnimation', { animationLauncherMorphDuration: 250 }, 'Launcher animation affects Animation only');
only('launcherApplications', { launcherFavoriteApps: ['firefox.desktop'] }, 'application preferences affect Applications only');
set({ launcherShowNavigationHints: false });
assert.strictEqual(context.settingsSubTabChangeSpec('launcher', 1).keys.includes('launcherShowNavigationHints'), true, 'navigation subtab includes the show checkbox');
assert.strictEqual(context.settingsSubTabChangeSpec('launcher', 0).keys.includes('launcherShowNavigationHints'), false, 'General subtab does not inherit navigation changes');
set({ launcherFuzzySearchActions: false });
assert.strictEqual(context.settingsSubTabChangeSpec('launcherSearch', 1).keys.includes('launcherFuzzySearchActions'), true, 'Search > Actions subtab tracks its own setting');
assert.strictEqual(context.settingsSubTabChangeSpec('launcherSearch', 0).keys.includes('launcherFuzzySearchActions'), false, 'Search > Apps subtab ignores the Actions setting');
set({ launcherDisabledBuiltinActions: ['tab.apps'] });
assert.strictEqual(context.settingsSubTabChangeSpec('launcherActions', 0).arrayContains.launcherDisabledBuiltinActions.includes('tab.apps'), true, 'Actions > Transitions tracks its own item');
assert.strictEqual(context.settingsSubTabChangeSpec('launcherActions', 1).arrayContains.launcherDisabledBuiltinActions.includes('tab.apps'), false, 'Actions > Tools ignores a transition item');
context.root.host.profileController.hasActiveProfile = false;
assert.strictEqual(dirty('launcher'), false, 'dirty sidebar indicators stay hidden without an active profile');
console.log('Launcher page and subtab dirty markers are scoped to their own settings: OK');
JS
