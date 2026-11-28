#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODULE="$ROOT/js/launcher/LauncherCustomActions.js"
LAUNCHER="$ROOT/components/launcher/Launcher.qml"
README="$ROOT/README.md"
README_EN="$ROOT/README.en.md"

node - "$MODULE" <<'JS'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const source = fs.readFileSync(process.argv[2], 'utf8').replace(/^\.pragma library\s*/, '');
const api = vm.runInThisContext(source + '\n({ parseQuery, buildResults })');

assert.deepStrictEqual(JSON.parse(JSON.stringify(api.parseQuery(':'))), { active: true, query: '' },
  'bare : opens the saved-action catalog');
assert.deepStrictEqual(JSON.parse(JSON.stringify(api.parseQuery(': terminal tools '))), { active: true, query: 'terminal tools' },
  'text after : is trimmed and used as the saved-action query');
for (const value of ['', 'terminal', '>terminal', '@k terminal', '.terminal']) {
  assert.strictEqual(api.parseQuery(value).active, false, `${value} must not activate the custom-action prefix`);
}

const actions = [
  { id: 'terminal', enabled: true, name: 'Terminal', description: 'Open a terminal', command: 'foot' },
  { id: 'disabled', enabled: false, name: 'Hidden', description: '', command: 'echo hidden' },
  { id: 'incomplete', enabled: true, name: 'Incomplete', description: '', command: '' }
];
const score = (text, query) => {
  text = String(text).toLowerCase(); query = String(query).toLowerCase();
  if (!query) return 0;
  if (text === query) return 10000;
  if (text.startsWith(query)) return 9000 - text.length;
  if (text.includes(query)) return 8000 - text.indexOf(query);
  return -1;
};
const all = api.buildResults(actions, api.parseQuery(':').query, score, 0, true);
assert.strictEqual(all.length, 1, 'bare : lists only enabled, complete saved actions');
assert.strictEqual(all[0].actionId, 'terminal');
const filtered = api.buildResults(actions, api.parseQuery(':term').query, score, 0, true);
assert.strictEqual(filtered.length, 1, ':term searches saved actions by name, description or command');
assert.strictEqual(filtered[0].command, 'foot', 'the result carries the saved command, not the raw search text');
JS

python3 - "$LAUNCHER" "$README" "$README_EN" <<'PY'
from pathlib import Path
import sys
launcher = Path(sys.argv[1]).read_text()
readme = Path(sys.argv[2]).read_text()
readme_en = Path(sys.argv[3]).read_text()
assert 'const customActionQuery = LauncherCustomActions.parseQuery(rawQuery)' in launcher
assert 'customActionQuery.query, 0, true, fuzzyActionsEnabled' in launcher
palette = launcher[launcher.index('function buildLauncherActionResults'):launcher.index('function russianApplicationCount')]
assert 'buildCustomActionResults' not in palette, 'built-in > palette must stay separate'
assert 'launcherQuery.startsWith(">") || launcherQuery.startsWith(":")' in launcher
assert 'if (result.kind === "customAction")' in launcher and 'root.runCommand(result.command)' in launcher
assert 'Search apps, @ filters, > commands or : saved actions...' in launcher
assert 'каталог сохранённых пользовательских действий' in readme, 'Russian README should document the dedicated custom-action prefix'
assert 'bare `:` lists all complete records' in readme_en, 'English README should document the dedicated custom-action prefix'
assert 'palette stays dedicated to built-in navigation' in readme_en, 'English README should document separation from built-in actions'
PY

printf 'Launcher custom-action prefix : is separate from built-in > palette: OK\n'
