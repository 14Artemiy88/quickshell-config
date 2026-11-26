#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LAYOUT="$ROOT/js/launcher/LauncherKeyboardLayout.js"
APP_SEARCH="$ROOT/js/launcher/LauncherAppSearch.js"
SCORING="$ROOT/js/launcher/LauncherSearchScoring.js"
APP_MODEL="$ROOT/components/launcher/models/AppModel.qml"
LAUNCHER="$ROOT/components/launcher/Launcher.qml"

node - "$LAYOUT" "$APP_SEARCH" "$SCORING" "$LAUNCHER" "$ROOT/js/launcher/LauncherCustomActions.js" "$ROOT/js/utils/ApplicationSearch.js" <<'JS'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const layoutSource = fs.readFileSync(process.argv[2], 'utf8').replace(/^\.pragma library\s*/, '');
const layout = vm.runInNewContext(layoutSource + '\n({ alternateLayoutQuery, scoreWithLayout, bestMatchingQuery })');
assert.strictEqual(layout.alternateLayoutQuery('щквукы'), 'orders', 'Russian-layout input converts to its QWERTY key sequence');
assert.strictEqual(layout.alternateLayoutQuery('ghbdtn'), 'привет', 'QWERTY input converts to its Russian-layout key sequence');
assert.strictEqual(layout.alternateLayoutQuery('ok'), '', 'short queries are not converted');
assert.strictEqual(layout.alternateLayoutQuery('orders щквукы'), '', 'mixed-language queries are left untouched');
assert.strictEqual(layout.alternateLayoutQuery('12345'), '', 'numeric queries are left untouched');

const loadScorer = (path) => {
  const source = fs.readFileSync(path, 'utf8')
    .replace(/^\.pragma library\s*/, '')
    .replace(/^\.import .*$/gm, '');
  const context = vm.createContext({ KeyboardLayout: layout });
  vm.runInContext(source + '\nthis.api = { fuzzyScore, fuzzyScoreNative };', context);
  return context.api;
};
const helperSource = fs.readFileSync(process.argv[7], 'utf8')
  .replace(/^\.pragma library\s*/, '')
  .replace(/^\.import .*$/gm, '');
const helperContext = vm.createContext({ KeyboardLayout: layout });
vm.runInContext(helperSource + '\nthis.api = { searchValue, fuzzyScoreCore, fuzzyScoreNative, fuzzyScore, valuesOf };', helperContext);
const appModuleSource = fs.readFileSync(process.argv[3], 'utf8')
  .replace(/^\.pragma library\s*/, '')
  .replace(/^\.import .*$/gm, '');
const appContext = vm.createContext({ ApplicationSearch: helperContext.api });
vm.runInContext(appModuleSource + '\nthis.api = { fuzzyScore };', appContext);
const appSearch = appContext.api;
const sharedScoring = loadScorer(process.argv[4]);
const strictScore = (text, query) => {
  text = String(text ?? '').toLowerCase().trim();
  query = String(query ?? '').toLowerCase().trim();
  if (!query) return 0;
  if (text === query) return 10000;
  if (text.startsWith(query)) return 9000 - text.length;
  if (text.includes(query)) return 8000 - text.indexOf(query);
  return -1;
};

assert(appSearch.fuzzyScore('Orders', 'щквукы', false) >= 0,
  'Apps strict search still supports an unambiguous keyboard-layout correction');
assert(sharedScoring.fuzzyScore('Orders', 'щквукы', false) >= 0,
  'shared Launcher search supports keyboard-layout correction in strict mode');
assert(sharedScoring.fuzzyScore('Привет', 'ghbdtn', false) >= 0,
  'shared Launcher search supports correction in the opposite direction');
assert(sharedScoring.fuzzyScore('Firefox', 'ащч', true) >= 0,
  'converted queries retain low-scoring fuzzy subsequence matches instead of dropping them');
assert.strictEqual(sharedScoring.fuzzyScore('Orders', 'ord', false), strictScore('Orders', 'ord'),
  'native-layout exact/prefix/substring scoring remains unchanged');
assert.strictEqual(layout.bestMatchingQuery('Orders', 'щквукы', strictScore), 'orders',
  'highlighting can use the converted query that actually matched');
assert.strictEqual(layout.bestMatchingQuery('Orders', 'orders', strictScore), 'orders',
  'highlighting keeps the original query when it matches directly');

const actionSource = fs.readFileSync(process.argv[6], 'utf8').replace(/^\.pragma library\s*/, '');
const actionApi = vm.runInThisContext(actionSource + '\n({ buildResults })');
const savedActions = [{ id: 'orders', enabled: true, name: 'Orders', description: 'Open orders workspace', command: 'orders' }];
const actionResults = actionApi.buildResults(savedActions, 'щквукы',
  (text, query) => sharedScoring.fuzzyScore(text, query, true), 0, true);
assert.strictEqual(actionResults.length, 1, 'the : custom-action search also corrects the typed layout');
assert.strictEqual(actionResults[0].actionId, 'orders', 'the intended saved action is returned');

const launcherSource = fs.readFileSync(process.argv[5], 'utf8');
const functionStart = launcherSource.indexOf('function nixSearchPayload(query) {');
assert(functionStart >= 0, 'Nix package payload builder exists');
let functionEnd = functionStart;
let braceDepth = 0;
let opened = false;
for (; functionEnd < launcherSource.length; ++functionEnd) {
  if (launcherSource[functionEnd] === '{') { braceDepth += 1; opened = true; }
  else if (launcherSource[functionEnd] === '}') {
    braceDepth -= 1;
    if (opened && braceDepth === 0) { functionEnd += 1; break; }
  }
}
const nixPayloadFunction = vm.runInNewContext(
  '(' + launcherSource.slice(functionStart, functionEnd) + ')',
  { LauncherKeyboardLayout: layout }
);
const nixPayload = JSON.parse(nixPayloadFunction('щквукы'));
const nixQueries = nixPayload.query.bool.must[0].dis_max.queries;
assert(nixQueries.some(item => item.multi_match && item.multi_match.query === 'orders'),
  'Nix search payload sends the converted query alongside the original');
JS

python3 - "$APP_MODEL" "$LAUNCHER" "$APP_SEARCH" "$SCORING" "$ROOT/js/utils/ApplicationSearch.js" <<'PY'
from pathlib import Path
import sys
app_model, launcher, app_search, scoring, app_search_core = [Path(value).read_text() for value in sys.argv[1:]]
assert 'LauncherKeyboardLayout.js' in launcher, 'Launcher imports the shared layout helper'
assert 'LauncherAppSearch.buildApplicationEntries(' in app_model, 'AppModel delegates the complete application-list pipeline to the shared primitive'
assert '../utils/ApplicationSearch.js' in app_search and 'ApplicationSearch.fuzzyScore(text, query, fuzzyEnabled)' in app_search, 'Launcher AppModel delegates to the extracted shared app-search primitive'
assert 'KeyboardLayout.scoreWithLayout(' in app_search_core, 'shared app-search primitive keeps keyboard-layout correction'
assert 'KeyboardLayout.scoreWithLayout(' in scoring, 'shared fuzzy scorer uses layout correction'
assert 'LauncherKeyboardLayout.scoreWithLayout(' in launcher, 'Window and Network local fuzzy scorers use layout correction'
assert 'const alternateQuery = LauncherKeyboardLayout.alternateLayoutQuery(query)' in launcher, 'Clipboard search checks the alternate query'
assert 'searchable.includes(alternateQuery)' in launcher, 'Clipboard results can match the converted query'
assert 'LauncherKeyboardLayout.alternateLayoutQuery(normalizedQuery)' in launcher, 'Nix package search includes the alternate-layout term'
assert 'LauncherKeyboardLayout.bestMatchingQuery(' in launcher, 'result highlighting selects the matching layout variant'
assert 'LauncherSearchScoring.fuzzyScoreNative(searchText, searchQuery, true)' in launcher, 'highlighting scores the original and converted query without double conversion'
assert 'root.fuzzyNetworkScoreCore(searchText, searchQuery)' in launcher, 'network highlighting compares original and converted queries without double conversion'
print('Launcher wrong-keyboard-layout search integration: OK')
PY

echo 'Launcher keyboard-layout search: OK'
