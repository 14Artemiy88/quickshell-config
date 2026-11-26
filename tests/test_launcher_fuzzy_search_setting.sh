#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
node - "$ROOT/js/launcher/LauncherAppSearch.js" "$ROOT/js/launcher/LauncherKeyboardLayout.js" "$ROOT/js/utils/ApplicationSearch.js" <<'JS'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const layoutSource = fs.readFileSync(process.argv[3], 'utf8').replace(/^\.pragma library\s*/, '');
const KeyboardLayout = vm.runInNewContext(layoutSource + '\n({ alternateLayoutQuery, scoreWithLayout, bestMatchingQuery })');
const helperSource = fs.readFileSync(process.argv[4], 'utf8').replace(/^\.pragma library\s*/, '').replace(/^\.import .*$/gm, '');
const helperContext = vm.createContext({ KeyboardLayout });
vm.runInContext(helperSource + '\nthis.api = { searchValue, fuzzyScoreCore, fuzzyScoreNative, fuzzyScore, valuesOf };', helperContext);
const ApplicationSearch = helperContext.api;
const source = fs.readFileSync(process.argv[2], 'utf8').replace(/^\.pragma library\s*/, '').replace(/^\.import .*$/gm, '');
const context = vm.createContext({ ApplicationSearch });
vm.runInContext(source + '\nthis.api = { fuzzyScore, parseSpecialQuery, scoreEntry };', context);
const api = context.api;

// The default fuzzy mode keeps the former subsequence behavior.
assert(api.fuzzyScore('Firefox', 'ff', true) >= 0, 'fuzzy mode matches non-contiguous letters');
assert.strictEqual(api.fuzzyScore('Firefox', 'ff', false), -1,
  'strict mode rejects a gapped subsequence');

// Exact, prefix, and contiguous substring matching are retained in both modes.
for (const [value, query] of [
  ['Firefox', 'firefox'],
  ['Firefox browser', 'firefox'],
  ['Mozilla Firefox browser', 'firefox']
]) {
  assert(api.fuzzyScore(value, query, true) >= 0, `${query} should match ${value} in fuzzy mode`);
  assert(api.fuzzyScore(value, query, false) >= 0, `${query} should match ${value} in strict mode`);
}
assert.strictEqual(api.fuzzyScore('Firefox', '', false), 0, 'empty query keeps the neutral score');
assert.strictEqual(api.fuzzyScore('Firefox', 'f x', false), -1, 'strict mode rejects spaced subsequences');

// The same preference controls metadata selectors through their injected scorer.
const app = {
  name: 'Firefox',
  keywords: ['browser', 'web client'],
  runInTerminal: false
};
const fuzzyKeyword = api.parseSpecialQuery('@k bsr');
const strictKeyword = api.parseSpecialQuery('@k bsr');
assert(api.scoreEntry(app, fuzzyKeyword, (value, query) => api.fuzzyScore(value, query, true)) >= 0,
  '@ metadata search follows fuzzy matching when enabled');
assert.strictEqual(api.scoreEntry(app, strictKeyword, (value, query) => api.fuzzyScore(value, query, false)), -1,
  '@ metadata search follows strict matching when fuzzy mode is disabled');
JS

node - "$ROOT/Config.qml" "$ROOT/js/settings/SettingsDefaults.js" "$ROOT/js/settings/SettingsApplySystemVisual.js" "$ROOT/js/settings/SettingsPersistence.js" "$ROOT/js/settings/SettingsResets.js" "$ROOT/components/settings/SettingsNavigationController.qml" "$ROOT/components/settings/sections/SettingsLauncherSection.qml" "$ROOT/components/launcher/models/AppModel.qml" <<'JS'
const fs = require('fs');
const assert = require('assert');
const [config, defaults, apply, persist, resets, navigation, ui, model] = process.argv.slice(2).map(p => fs.readFileSync(p, 'utf8'));
assert(config.includes('property bool launcherFuzzySearchApps: true'), 'Config defaults fuzzy app search to enabled');
assert(defaults.includes('launcherFuzzySearchApps: true'), 'settings defaults enable fuzzy app search');
assert(apply.includes('if (o.launcherFuzzySearchApps !== undefined)') && apply.includes('Config.launcherFuzzySearchApps = !!o.launcherFuzzySearchApps'),
  'settings application restores the switch');
assert(persist.includes('launcherFuzzySearchApps: config.launcherFuzzySearchApps'), 'settings persistence stores the switch');
assert(resets.includes('"launcherFuzzySearchApps"'), 'Launcher reset includes the switch');
assert(resets.includes('if (profile.launcherFuzzySearchApps === undefined) config.launcherFuzzySearchApps = true'),
  'older profiles retain the former fuzzy behavior');
assert(ui.includes('heading: "Поиск приложений"') && ui.includes('launcherFuzzySearchAppsCheckBox'),
  'Launcher Search exposes the fuzzy-search control');
assert(ui.includes('visible: root.host && root.host.currentPageId === \"launcherSearch\" && root.host.currentPageSubTabIndex === 0\n        settingsSearchSubTabIndex: 0\n\n        width: parent.width\n        showFrame: true\n        changeKeys: ({ keys: [\"launcherFuzzySearchApps\"] })'),
  'Apps fuzzy-search control is placed in the Search subtab');
assert(ui.includes('Config.launcherFuzzySearchApps = checked') && ui.includes('root.settings.save()'),
  'changing the control persists the preference');
assert(model.includes('readonly property bool fuzzySearchEnabled: Config.launcherFuzzySearchApps !== false'),
  'AppModel tracks the preference reactively');
assert(model.includes('LauncherAppSearch.buildApplicationEntries('),
  'AppModel delegates the complete application query pipeline to the canonical shared primitive');
const begin = navigation.indexOf('"launcherSearch": [');
const end = navigation.indexOf('\n            ],', begin);
assert(begin >= 0 && end > begin, 'find Launcher dirty-state mapping');
assert(navigation.slice(begin, end).includes('launcherFuzzySearchApps'), 'Apps search subtab tracks the preference as a profile change');
assert(navigation.slice(begin, end).includes('launcherFuzzySearchActions') && navigation.slice(begin, end).includes('launcherFuzzySearchSchemes') && navigation.slice(begin, end).includes('launcherFuzzySearchWallpapers'), 'fuzzy-search preferences are distributed across Launcher Search subtabs');
assert(!navigation.slice(navigation.indexOf('\"launcher\": ['), begin).includes('launcherFuzzySearchApps'), 'General no longer owns Apps fuzzy-search preferences');
JS
