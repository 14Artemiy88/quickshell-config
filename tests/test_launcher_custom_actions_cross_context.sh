#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SETTINGS_MODULE="$ROOT/js/settings/SettingsLauncherActions.js"
SEARCH_MODULE="$ROOT/js/launcher/LauncherCustomActions.js"
APPLY_MODULE="$ROOT/js/settings/SettingsApplySystemVisual.js"

node - "$SETTINGS_MODULE" "$SEARCH_MODULE" "$APPLY_MODULE" <<'JS'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');

function loadLibrary(path, injected = {}) {
  const context = vm.createContext(injected);
  const source = fs.readFileSync(path, 'utf8')
    .replace(/^\.pragma library\s*/, '')
    .replace(/^\.import .*\n/gm, '');
  vm.runInContext(source, context, { filename: path });
  return context;
}

const settings = loadLibrary(process.argv[2]);
const search = loadLibrary(process.argv[3]);

// Simulate Config.qml owning an array that is passed into imported .pragma
// library scripts, each of which may have a different JavaScript realm.
const configActions = [{
  id: 'terminal', enabled: true, icon: 'terminal', name: 'Terminal',
  description: 'Open a terminal', command: 'foot'
}];

const updated = settings.update(configActions, 0, 'command', 'foot');
assert.strictEqual(updated.length, 1, 'settings update must preserve foreign-realm array');
assert.strictEqual(updated[0].name, 'Terminal');
assert.strictEqual(updated[0].command, 'foot');

function score(text, query) {
  const value = String(text).toLowerCase();
  const needle = String(query).toLowerCase();
  if (value === needle) return 10000;
  if (value.startsWith(needle)) return 9000 - value.length;
  if (value.includes(needle)) return 8000 - value.indexOf(needle);
  return -1;
}
const results = search.buildResults(updated, 'terminal', score, 0, false);
assert.strictEqual(results.length, 1, 'search helper must accept foreign-realm action list');
assert.strictEqual(results[0].name, 'Terminal');
assert.strictEqual(search.buildResults(updated, 'foot', score, 0, false).length, 1);

// Reproduce the actual runtime load path. SettingsApplySystemVisual is a
// separate imported .pragma library and receives JSON/profile arrays from the
// QML settings loader. `instanceof Array` rejected those arrays; Array.isArray
// must accept them and place the action into Config before Launcher searches.
const applySource = fs.readFileSync(process.argv[4], 'utf8')
  .replace(/^\.pragma library\s*/, '')
  .replace(/^\.import .*\n/gm, '');
const shared = {};
const applyContext = vm.createContext({
  LauncherActions: {
    normalize(source) {
      shared.normalizedInput = source;
      return Array.from(source, item => ({ ...item }));
    }
  },
  LauncherProjects: { normalize: source => Array.from(source) },
  Schema: { normalizeSavedColor: (value) => value }
});
vm.runInContext(applySource, applyContext, { filename: process.argv[4] });
const foreignRealmActions = vm.runInNewContext(`JSON.parse(${JSON.stringify(JSON.stringify([{
  id: 'terminal', enabled: true, icon: 'terminal', name: 'Terminal',
  description: 'Open a terminal', command: 'foot'
}]))})`);
assert.strictEqual(foreignRealmActions instanceof Array, false,
  'fixture must really be an Array from another JavaScript realm');
assert.strictEqual(Array.isArray(foreignRealmActions), true);
const config = { launcherCustomActions: [] };
applyContext.apply(config, { launcherCustomActions: foreignRealmActions });
assert.ok(shared.normalizedInput, 'settings apply must invoke custom-action normalizer');
assert.strictEqual(config.launcherCustomActions.length, 1,
  'runtime settings load must retain custom actions from another realm');
assert.strictEqual(config.launcherCustomActions[0].command, 'foot');
JS

grep -Fq 'if (Array.isArray(o.launcherCustomActions))' "$APPLY_MODULE"
printf 'custom actions survive settings load across JavaScript realms and remain searchable: OK\n'
