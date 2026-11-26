#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MODULE="$ROOT/js/launcher/LauncherAppSearch.js"
APP_MODEL="$ROOT/components/launcher/models/AppModel.qml"
LAUNCHER="$ROOT/components/launcher/Launcher.qml"

node - "$MODULE" "$ROOT/js/utils/ApplicationSearch.js" "$ROOT/js/launcher/LauncherKeyboardLayout.js" <<'JS'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const layoutSource = fs.readFileSync(process.argv[4], 'utf8').replace(/^\.pragma library\s*/, '');
const KeyboardLayout = vm.runInNewContext(layoutSource + '\n({ alternateLayoutQuery, scoreWithLayout, bestMatchingQuery })');
const helperSource = fs.readFileSync(process.argv[3], 'utf8').replace(/^\.pragma library\s*/, '').replace(/^\.import .*$/gm, '');
const helperContext = vm.createContext({ KeyboardLayout });
vm.runInContext(helperSource + '\nthis.api = { searchValue, fuzzyScoreCore, fuzzyScoreNative, fuzzyScore, valuesOf };', helperContext);
const source = fs.readFileSync(process.argv[2], 'utf8').replace(/^\.pragma library\s*/, '').replace(/^\.import .*$/gm, '');
const appContext = vm.createContext({ ApplicationSearch: helperContext.api });
vm.runInContext(source + '\nthis.api = { collectCategories, displayCategoryName };', appContext);
const api = appContext.api;

const entries = [
  { id: 'org.example.graphics.desktop', categories: ['Graphics', 'Utility', 'Graphics'] },
  { id: 'org.example.editor.desktop', categories: ['Utility', 'Development'] },
  { id: 'org.example.video.desktop', categories: { 0: 'AudioVideo', 1: 'Video', length: 2 } },
  { id: 'org.example.hidden.desktop', categories: ['Game', 'Graphics'] },
  { id: 'org.example.empty.desktop', categories: ['', null] },
  { id: 'org.example.single.desktop', categories: 'Utility' }
];
const categories = api.collectCategories(entries, ['org.example.hidden.desktop']);
assert.deepStrictEqual(Array.from(categories, item => item.name),
  ['AudioVideo', 'Development', 'Graphics', 'Utility', 'Video'],
  'categories are unique and sorted alphabetically by display label');
assert.deepStrictEqual(Array.from(categories, item => item.count), [1, 1, 1, 3, 1],
  'counts include each visible app once per category and exclude hidden apps');
assert.strictEqual(categories[0].label, 'Audio Video', 'camel-case categories receive a readable label');
assert.strictEqual(api.displayCategoryName('X-KDE_Games'), 'X KDE Games', 'category labels normalize separators');
assert.strictEqual(api.collectCategories([{ id: 'one', categories: 'Utility' }], [])[0].count, 1,
  'a single category string is treated as one category, not as individual characters');
assert.deepStrictEqual(Array.from(api.collectCategories([], [])), [], 'an empty desktop-entry catalog returns no categories');
JS

python3 - "$APP_MODEL" "$LAUNCHER" <<'PY'
from pathlib import Path
import sys
model = Path(sys.argv[1]).read_text()
launcher = Path(sys.argv[2]).read_text()
assert 'LauncherAppSearch.collectCategories(' in model
assert 'DesktopEntries.applications.values || [], root.hiddenAppIds' in model
assert 'appModel.applications, root.fuzzyCustomActionsEnabled, appModel.availableCategories' in launcher
assert 'function buildAppsUnifiedResults(applicationEntries, fuzzyActionsEnabled, availableCategories, fuzzySchemesEnabled, fuzzyWallpapersEnabled)' in launcher
assert 'appModel.specialSearch.code === "c"' in launcher and 'appModel.specialSearch.query === ""' in launcher
assert 'kind: "appCategory"' in launcher
assert 'if (result.kind === "appCategory")' in launcher
assert 'searchField.text = "@c " + category' in launcher
assert 'itemData.kind === "appCategory"' in launcher
assert 'нажмите Enter, чтобы открыть категорию' in launcher
assert 'приложений' in launcher and 'приложение' in launcher and 'приложения' in launcher
# Once a category is selected, normal special metadata search remains app-only.
assert 'if (appModel.specialSearch)\n            return results' in launcher
print('Launcher app category browser integration: OK')
PY

echo 'Launcher app categories: OK'
