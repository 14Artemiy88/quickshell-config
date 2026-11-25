#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ACTIONS="$ROOT/js/settings/SettingsLauncherActions.js"
CONFIG="$ROOT/Config.qml"
DEFAULTS="$ROOT/js/settings/SettingsDefaults.js"
PERSIST="$ROOT/js/settings/SettingsPersistence.js"
APPLY="$ROOT/js/settings/SettingsApplySystemVisual.js"
RESETS="$ROOT/js/settings/SettingsResets.js"
SETTINGS="$ROOT/Settings.qml"
REGISTRY="$ROOT/js/settings/SettingsPageRegistry.js"
SECTION="$ROOT/components/settings/sections/SettingsLauncherSection.qml"
LAUNCHER="$ROOT/components/launcher/Launcher.qml"

# The catalog uses bounded, normalized records and stable unique IDs.
node - "$ACTIONS" <<'JS'
const fs = require('fs');
const vm = require('vm');
const source = fs.readFileSync(process.argv[2], 'utf8').replace(/^\.pragma library\s*/, '');
const api = vm.runInThisContext(source + '\n({ normalize, add, update, remove, move, moveTo })');
const assert = require('assert');
assert.deepStrictEqual(JSON.parse(JSON.stringify(api.normalize(undefined))), []);
const clean = api.normalize([
  { id: 'custom-1', enabled: true, icon: ' X\n', name: ' Build\nnow ', description: 'Compile\tproject', command: 'nix build\n.' },
  { id: 'custom-1', name: 'Second', command: 'echo second' },
  { name: 'Third', command: 'echo third' }
]);
assert.strictEqual(clean.length, 3);
assert.strictEqual(clean[0].name, 'Build now');
assert.strictEqual(clean[0].description, 'Compile project');
assert.strictEqual(clean[0].command, 'nix build .');
assert.strictEqual(clean[0].icon, 'X');
assert.notStrictEqual(clean[0].id, clean[1].id, 'duplicate IDs must be repaired');
assert.strictEqual(clean[1].enabled, true, 'enabled defaults to true');
assert.strictEqual(api.normalize(clean.concat(Array(110).fill({name:'x'}))).length, 100, 'catalog is bounded');
const added = api.add(clean);
assert.strictEqual(added.length, 4);
assert.strictEqual(added[3].command, '');
assert.strictEqual(added[3].name, '', 'new actions must not contain sample text in the name field');
assert.strictEqual(added[3].description, '', 'new actions must not contain sample text in the optional description field');
assert.strictEqual(api.update(added, 3, 'enabled', false)[3].enabled, false);
assert.strictEqual(api.update(added, 3, 'command', 'foot -- nvim ~/WORK\n').at(-1).command, 'foot -- nvim ~/WORK');
assert.strictEqual(api.update(added, 3, 'id', 'overwritten')[3].id, added[3].id, 'ID is immutable through field editing');
assert.strictEqual(api.move(added, 0, 1)[0].id, added[1].id);
assert.strictEqual(api.moveTo(added, 0, 2)[2].id, added[0].id, 'drag reorder moves a record to an exact destination');
assert.strictEqual(api.remove(added, 1).length, 3);
JS

# Catalog participates in defaults, runtime loading, snapshots and profile reset.
grep -Fq 'property var launcherCustomActions: LauncherActions.normalize([])' "$CONFIG"
grep -Fq 'launcherCustomActions: LauncherActions.normalize([])' "$DEFAULTS"
grep -Fq 'launcherCustomActions: JSON.parse(JSON.stringify(config.launcherCustomActions' "$PERSIST"
grep -Fq 'if (Array.isArray(o.launcherCustomActions))' "$APPLY"
grep -Fq 'Config.launcherCustomActions = LauncherActions.normalize(o.launcherCustomActions)' "$APPLY"
grep -Fq '"launcherCustomActions"' "$RESETS"
grep -Fq 'if (profile.launcherCustomActions === undefined) config.launcherCustomActions = []' "$RESETS"
grep -Fq 'function updateLauncherCustomAction(index, field, value)' "$SETTINGS"
grep -Fq 'function addLauncherCustomAction()' "$SETTINGS"
grep -Fq 'function removeLauncherCustomAction(index)' "$SETTINGS"
grep -Fq 'function moveLauncherCustomAction(index, delta)' "$SETTINGS"
grep -Fq 'function moveLauncherCustomActionTo(fromIndex, toIndex)' "$SETTINGS"

# User actions are edited in their own launcher subtab and appear in the : catalog only when complete and enabled.
grep -Fq '{ id: "launcherActions", saveScope: "launcher", subTabs: ["Переходы", "Инструменты", "Пользовательские"] }' "$REGISTRY"
grep -Fq 'currentPageId === "launcherActions" && root.host.currentPageSubTabIndex === 2' "$SECTION"
grep -Fq 'currentPageId === "launcherAnimation"' "$SECTION"
grep -Fq 'placeholderText: "Команда для запуска (обязательно)' "$SECTION"
grep -Fq 'placeholderText: "Краткое описание действия (необязательно)' "$SECTION"
grep -Fq 'placeholderText: "Название действия (обязательно)' "$SECTION"
grep -Fq 'onClicked: root.settings.addLauncherCustomAction()' "$SECTION"
grep -Fq 'enabled: !(Array.isArray(Config.launcherCustomActions)) || Config.launcherCustomActions.length < 100' "$SECTION"
grep -Fq 'function buildLauncherActionResults(query, fuzzyActionsEnabled, fuzzySchemesEnabled, fuzzyWallpapersEnabled)' "$LAUNCHER"
grep -Fq 'kind: "customAction"' "$ROOT/js/launcher/LauncherCustomActions.js"
grep -Fq 'function appsResultSubtitle(itemData, entry)' "$LAUNCHER"
grep -Fq 'action.enabled === false' "$ROOT/js/launcher/LauncherCustomActions.js"
grep -Fq 'if (!name || !command)' "$ROOT/js/launcher/LauncherCustomActions.js"
grep -Fq 'if (result.kind === "customAction")' "$LAUNCHER"
grep -Fq 'root.runCommand(result.command)' "$LAUNCHER"

printf 'launcher user-defined action catalog, persistence, editor and safe saved-record activation: OK\n'
