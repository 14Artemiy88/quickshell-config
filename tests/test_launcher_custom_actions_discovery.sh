#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MODULE="$ROOT/js/launcher/LauncherCustomActions.js"
LAUNCHER="$ROOT/components/launcher/Launcher.qml"

node - "$MODULE" <<'JS'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const source = fs.readFileSync(process.argv[2], 'utf8').replace(/^\.pragma library\s*/, '');
const api = vm.runInThisContext(source + '\n({ buildResults })');
const actions = [
  { id: 'terminal', enabled: true, name: 'Terminal', description: 'Open terminal here', command: 'foot' },
  { id: 'disabled', enabled: false, name: 'Hidden action', description: 'No show', command: 'echo hidden' },
  { id: 'incomplete', enabled: true, name: 'Incomplete', description: 'Missing command', command: '' }
];
const score = (text, query) => {
  text = String(text).toLowerCase(); query = String(query).toLowerCase();
  if (!query) return 0;
  if (text === query) return 10000;
  if (text.startsWith(query)) return 9000 - text.length;
  if (text.includes(query)) return 8000 - text.indexOf(query);
  return -1;
};
const withoutDescription = api.buildResults([{ id: 'plain', enabled: true, name: 'Plain', description: '', command: 'echo plain' }], 'plain', score, 0, false);
assert.strictEqual(withoutDescription[0].description, 'Пользовательское действие', 'empty optional description gets a neutral result subtitle');
const byName = api.buildResults(actions, 'terminal', score, 0, false);
assert.strictEqual(byName.length, 1, 'ordinary search finds named action');
assert.strictEqual(byName[0].command, 'foot');
const byCommand = api.buildResults(actions, 'foot', score, 4, false);
assert.strictEqual(byCommand.length, 1, 'ordinary search finds action by command');
assert.strictEqual(byCommand[0].order, 4);
const byDescription = api.buildResults(actions, 'terminal here', score, 0, false);
assert.strictEqual(byDescription.length, 1, 'ordinary search finds action by description');
assert.strictEqual(api.buildResults(actions, 'hidden', score, 0, false).length, 0, 'disabled action is hidden');
assert.strictEqual(api.buildResults(actions, 'incomplete', score, 0, false).length, 0, 'action without command is hidden');
assert.strictEqual(api.buildResults(actions, '', score, 0, false).length, 0, 'empty ordinary search does not clutter results');
assert.strictEqual(api.buildResults(actions, '', score, 0, true).length, 1, 'bare > palette lists enabled complete actions');
JS

grep -Fq 'import "../../js/launcher/LauncherCustomActions.js" as LauncherCustomActions' "$LAUNCHER"
grep -Fq 'function buildCustomActionResults(query, orderOffset, includeEmptyQuery, fuzzyEnabled)' "$LAUNCHER"
grep -Fq 'const customActionResults = root.buildCustomActionResults(' "$LAUNCHER"
grep -Fq 'query, results.length, false, fuzzyActionsEnabled' "$LAUNCHER"
grep -Fq 'customAction: 2' "$LAUNCHER"
grep -Fq 'startsWith(">"))' "$LAUNCHER"
printf 'custom actions are discoverable by ordinary Apps search and > from any Launcher tab: OK\n'
