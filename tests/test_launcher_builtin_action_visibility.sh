#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODULE="$ROOT/js/launcher/LauncherBuiltinActions.js"
LAUNCHER="$ROOT/components/launcher/Launcher.qml"
SETTINGS="$ROOT/components/settings/sections/SettingsLauncherSection.qml"
APPLY="$ROOT/js/settings/SettingsApplySystemVisual.js"
PERSISTENCE="$ROOT/js/settings/SettingsPersistence.js"
RESETS="$ROOT/js/settings/SettingsResets.js"
CONFIG="$ROOT/Config.qml"
DEFAULTS="$ROOT/js/settings/SettingsDefaults.js"
README="$ROOT/README.md"
README_EN="$ROOT/README.en.md"

node - "$MODULE" "$APPLY" <<'JS'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const modulePath = process.argv[2];
const source = fs.readFileSync(modulePath, 'utf8').replace(/^\.pragma library\s*/, '');
const api = vm.runInThisContext(source + '\n({ tabActions, toolActions, knownIds, normalizeDisabledIds, isEnabled, setEnabled })');

assert.strictEqual(api.tabActions.length, 10, 'all ten launcher tab shortcuts should have independent toggles');
assert.strictEqual(api.toolActions.length, 6, 'all six built-in tools should have independent toggles');
assert.strictEqual(api.knownIds().length, 16, 'the palette should expose sixteen configurable built-in entries');
assert.strictEqual(api.isEnabled([], 'tab.apps'), true, 'all built-in entries are enabled by default');
assert.strictEqual(api.isEnabled(undefined, 'tool.emoji'), true, 'missing legacy settings enable all entries');

let disabled = api.setEnabled([], 'tab.network', false);
assert.deepStrictEqual(disabled, ['tab.network']);
assert.strictEqual(api.isEnabled(disabled, 'tab.network'), false);
assert.strictEqual(api.isEnabled(disabled, 'tab.apps'), true, 'one toggle must not affect another action');
disabled = api.setEnabled(disabled, 'tab.network', true);
assert.deepStrictEqual(disabled, [], 're-enabling an action removes only its disabled ID');
disabled = api.normalizeDisabledIds(['tab.apps', 'tab.apps', 'unknown', null, 'tool.wallpapers']);
assert.deepStrictEqual(disabled, ['tab.apps', 'tool.wallpapers'], 'profile data must be deduplicated and limited to known stable IDs');

const applyPath = process.argv[3];
let applySource = fs.readFileSync(applyPath, 'utf8').replace(/^\.pragma library\s*/, '').replace(/^\.import .*$/gm, '');
const Config = {};
const context = { Config, LauncherBuiltinActions: api, Math, Number, String, Boolean, Array, isFinite };
vm.runInNewContext(applySource + '\nthis.applyVisual = apply;', context);
context.applyVisual(Config, { launcherDisabledBuiltinActions: ['tool.emoji', 'invalid', 'tool.emoji'] });
assert.deepStrictEqual(Array.from(Config.launcherDisabledBuiltinActions), ['tool.emoji'], 'profile application must normalize saved disabled IDs');
console.log('Launcher built-in action IDs, defaults, independent toggles and profile normalization: OK');
JS

python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
launcher = (root / "components/launcher/Launcher.qml").read_text()
settings = (root / "components/settings/sections/SettingsLauncherSection.qml").read_text()
config = (root / "Config.qml").read_text()
defaults = (root / "js/settings/SettingsDefaults.js").read_text()
persistence = (root / "js/settings/SettingsPersistence.js").read_text()
resets = (root / "js/settings/SettingsResets.js").read_text()
apply = (root / "js/settings/SettingsApplySystemVisual.js").read_text()
readme = (root / "README.md").read_text()
readme_en = (root / "README.en.md").read_text()

assert 'property var launcherDisabledBuiltinActions: []' in config
assert 'launcherDisabledBuiltinActions: []' in defaults
assert 'launcherDisabledBuiltinActions: JSON.parse(JSON.stringify(config.launcherDisabledBuiltinActions || []))' in persistence
assert '"launcherDisabledBuiltinActions"' in resets and 'Array.isArray(profile.launcherDisabledBuiltinActions)' in resets and ': []' in resets
assert 'LauncherBuiltinActions.normalizeDisabledIds(o.launcherDisabledBuiltinActions)' in apply
assert 'function builtinActionEnabled(actionId)' in launcher
assert 'function builtinActionIdForMode(mode)' in launcher
palette = launcher[launcher.index('function buildLauncherActionResults'):launcher.index('function russianApplicationCount')]
for action_id in ('tool.schemeVariants', 'tool.wallpaperDynamic', 'tool.colorSchemes', 'tool.wallpapers', 'tool.emoji', 'tool.dashboard'):
    assert f'builtinActionEnabled("{action_id}")' in palette, f'{action_id} must be filtered from the > palette'
for tab_id in ('tab.apps', 'tab.run', 'tab.windows', 'tab.clipboard', 'tab.power', 'tab.network', 'tab.packages', 'tab.pass', 'tab.projects', 'tab.calculator'):
    assert f'return "{tab_id}"' in launcher, f'{tab_id} must use a stable tab ID, independent of its editable label'
assert 'if (!root.builtinActionEnabled(root.builtinActionIdForMode(tab.mode))) continue' in palette
assert 'function setBuiltinActionEnabled(actionId, enabled)' in settings
assert settings.count('changeKeys: ({ arrayContains: { launcherDisabledBuiltinActions: [') == 2
assert '"tab.apps"' in settings and '"tab.calculator"' in settings
assert '"tool.colorSchemes"' in settings and '"tool.wallpaperDynamic"' in settings and '"tool.dashboard"' in settings
assert 'model: LauncherBuiltinActions.tabActions' in settings and 'model: LauncherBuiltinActions.toolActions' in settings
assert 'Переходы между вкладками' in settings and 'Инструменты' in settings
assert 'Каталог пользовательских действий : не затрагивается.' in settings
assert 'launcherQuery.startsWith(":")' in launcher, 'the separate custom-action catalog must remain available'
assert 'Настройки → Лаунчер → Действия → Переходы' in readme
assert 'can be independently hidden from the `>` palette' in readme_en
# The visible tab list itself remains independent from the palette-only setting.
visible_tabs = launcher[launcher.index('readonly property var displayedModeTabs'):launcher.index('readonly property int selectedModeTabIndex')]
assert 'launcherDisabledBuiltinActions' not in visible_tabs, 'palette toggles must not hide or disable actual tabs'
print('Launcher built-in action visibility: QML gating, settings rows, profile persistence, and documentation: OK')
PY
