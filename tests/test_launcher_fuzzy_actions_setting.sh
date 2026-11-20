#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MODULE="$ROOT/js/launcher/LauncherSearchScoring.js"
ACTIONS="$ROOT/js/launcher/LauncherCustomActions.js"
LAUNCHER="$ROOT/components/launcher/Launcher.qml"
CONFIG="$ROOT/Config.qml"
DEFAULTS="$ROOT/js/settings/SettingsDefaults.js"
APPLY="$ROOT/js/settings/SettingsApplySystemVisual.js"
PERSIST="$ROOT/js/settings/SettingsPersistence.js"
RESETS="$ROOT/js/settings/SettingsResets.js"
NAV="$ROOT/components/settings/SettingsNavigationController.qml"
UI="$ROOT/components/settings/sections/SettingsLauncherSection.qml"
README="$ROOT/README.md"

node - "$MODULE" "$ACTIONS" "$ROOT/js/launcher/LauncherKeyboardLayout.js" <<'JS'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const layoutSource = fs.readFileSync(process.argv[4], 'utf8').replace(/^\.pragma library\s*/, '');
const KeyboardLayout = vm.runInNewContext(layoutSource + '\n({ alternateLayoutQuery, scoreWithLayout, bestMatchingQuery })');
const source = fs.readFileSync(process.argv[2], 'utf8').replace(/^\.pragma library\s*/, '').replace(/^\.import .*$/m, '');
const context = vm.createContext({ KeyboardLayout });
vm.runInContext(source + '\nthis.api = { fuzzyScore };', context);
const api = context.api;
const actionSource = fs.readFileSync(process.argv[3], 'utf8').replace(/^\.pragma library\s*/, '');
const actionApi = vm.runInThisContext(actionSource + '\n({ buildResults })');

// Fuzzy enabled remains byte-for-byte compatible with the prior Run scorer.
function previousScore(text, query) {
  text = String(text ?? '').toLowerCase().trim();
  query = String(query ?? '').toLowerCase().trim();
  if (query === '') return 0;
  if (text === query) return 10000;
  if (text.startsWith(query)) return 9000 - text.length;
  if (text.includes(query)) return 8000 - text.indexOf(query);
  let score = 0, position = 0, previousMatch = -1;
  for (let i = 0; i < query.length; ++i) {
    const found = text.indexOf(query[i], position);
    if (found === -1) return -1;
    if (previousMatch >= 0) {
      const gap = found - previousMatch - 1;
      score += gap === 0 ? 500 : Math.max(0, 200 - gap * 30);
    }
    if (found === 0 || text[found - 1] === ' ' || text[found - 1] === '/' || text[found - 1] === '-' || text[found - 1] === '_' || text[found - 1] === '.') score += 300;
    score += Math.max(0, 200 - found * 10);
    previousMatch = found;
    position = found + 1;
  }
  return score;
}
for (const [text, query] of [
  ['Firefox', 'ff'], ['Open terminal here', 'oth'], ['foot --server', 'fs'],
  ['My action command', 'mac'], ['Run command', 'run'], ['foo/bar-baz', 'fbb'],
  ['Exact', 'exact'], ['Prefix match', 'pre'], ['Middle substring', 'string']
]) {
  assert.strictEqual(api.fuzzyScore(text, query, true), previousScore(text, query),
    `enabling fuzzy search must preserve previous score for ${text}/${query}`);
}

const actions = [
  { id: 'firefox', enabled: true, name: 'Firefox tools', description: 'Open browser', command: 'firefox --new-window' },
  { id: 'terminal', enabled: true, name: 'Terminal', description: 'Open terminal here', command: 'foot' },
  { id: 'disabled', enabled: false, name: 'Hidden action', description: 'No show', command: 'echo hidden' }
];
const build = (query, fuzzyEnabled, includeEmpty = false) => actionApi.buildResults(
  actions, query,
  (text, q) => api.fuzzyScore(text, q, fuzzyEnabled),
  0, includeEmpty
);
assert.strictEqual(build('fx', true).length, 1, 'fuzzy search finds a saved action by a gapped name match');
assert.strictEqual(build('fx', false).length, 0, 'strict search rejects a gapped name match');
assert.strictEqual(build('fire', false)[0].actionId, 'firefox', 'strict search preserves prefix matching');
assert.strictEqual(build('fox tools', false)[0].actionId, 'firefox', 'strict search preserves contiguous substring matching');
assert.strictEqual(build('firefox --new-window', false)[0].actionId, 'firefox', 'strict search can match command text contiguously');
assert.strictEqual(build('oth', true)[0].actionId, 'terminal', 'fuzzy search also searches descriptions');
assert.strictEqual(build('oth', false).length, 0, 'strict mode disables gapped description matches');
assert.strictEqual(build('', true).length, 0, 'ordinary Apps search stays empty for a blank query');
assert.strictEqual(build('', true, true).length, 2, 'the : custom-action catalog lists complete enabled actions');
JS

node - "$CONFIG" "$DEFAULTS" "$APPLY" "$PERSIST" "$RESETS" "$NAV" "$UI" "$LAUNCHER" "$README" <<'JS'
const fs = require('fs');
const assert = require('assert');
const [config, defaults, apply, persist, resets, nav, ui, launcher, readme] = process.argv.slice(2).map(p => fs.readFileSync(p, 'utf8'));
assert(config.includes('property bool launcherFuzzySearchActions: true'), 'Config defaults action fuzzy search to enabled');
assert(defaults.includes('launcherFuzzySearchActions: true'), 'settings defaults enable action fuzzy search');
assert(apply.includes('if (o.launcherFuzzySearchActions !== undefined)') && apply.includes('Config.launcherFuzzySearchActions = !!o.launcherFuzzySearchActions'), 'profile application restores the setting');
assert(persist.includes('launcherFuzzySearchActions: config.launcherFuzzySearchActions'), 'persistence stores the setting');
assert(resets.includes('"launcherFuzzySearchActions"'), 'Launcher reset includes the setting');
assert(resets.includes('if (profile.launcherFuzzySearchActions === undefined) config.launcherFuzzySearchActions = true'), 'older profiles preserve current fuzzy behavior');
assert(nav.includes('launcherFuzzySearchActions'), 'Launcher Search subtab dirty-state mapping includes the setting');
assert(ui.includes('heading: "Поиск действий"') && ui.includes('launcherFuzzySearchActionsCheckBox'), 'Search subtab exposes a separate actions search group');
assert(ui.includes('Config.launcherFuzzySearchActions = checked') && ui.includes('root.settings.save()'), 'switch persists its value');
assert(launcher.includes('readonly property bool fuzzyCustomActionsEnabled: Config.launcherFuzzySearchActions !== false'), 'Launcher tracks the preference reactively');
assert(launcher.includes('function buildCustomActionResults(query, orderOffset, includeEmptyQuery, fuzzyEnabled)'), 'custom action results receive the configured mode');
assert(launcher.includes('return LauncherSearchScoring.fuzzyScore(\n                    searchText, normalizedQuery, fuzzyEnabled !== false'), 'custom action results use the configured scorer');
assert(launcher.includes('return root.buildAppsUnifiedResults(\n            appModel.applications, root.fuzzyCustomActionsEnabled'), 'Apps result binding explicitly depends on the setting');
assert(launcher.includes('const customActionQuery = LauncherCustomActions.parseQuery(rawQuery)'), 'the dedicated : catalog parses its own prefix');
assert(launcher.includes('customActionQuery.query, 0, true, fuzzyActionsEnabled'), 'the : catalog uses the independent action fuzzy-search setting');
const builtinPalette = launcher.slice(launcher.indexOf('function buildLauncherActionResults'), launcher.indexOf('function russianApplicationCount'));
assert(!builtinPalette.includes('buildCustomActionResults'), 'the > palette no longer includes custom entries');
assert(launcher.includes('query, results.length, false, fuzzyActionsEnabled'), 'ordinary Apps search keeps its existing custom-action cross-search');
assert(launcher.includes('import "../../js/launcher/LauncherSearchScoring.js" as LauncherSearchScoring'), 'Launcher imports shared scorer');
assert(launcher.includes('return LauncherSearchScoring.fuzzyScore(text, query, true)'), 'Run and project matching retain the previous fuzzy behavior');
assert(readme.includes('пользовательских действий') && readme.includes('saved custom actions'), 'both README languages document independent action search mode');
JS
printf 'launcher fuzzy custom-action setting: OK\n'
