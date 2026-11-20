#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ACTIONS="$ROOT/js/settings/SettingsLauncherActions.js"
SETTINGS="$ROOT/Settings.qml"
SECTION="$ROOT/components/settings/sections/SettingsLauncherSection.qml"
INPUT="$ROOT/components/settings/primitives/SettingsInputField.qml"

node - "$ACTIONS" <<'JS'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const source = fs.readFileSync(process.argv[2], 'utf8').replace(/^\.pragma library\s*/, '');
const api = vm.runInThisContext(source + '\n({ add, updateFields, validateRequiredFields })');
const catalog = api.add([]);
assert.strictEqual(catalog[0].name, '', 'new action name starts empty and is shown as a placeholder');
assert.strictEqual(catalog[0].description, '', 'new action description starts empty and is shown as a placeholder');
assert.strictEqual(catalog[0].command, '', 'new action command starts empty and is shown as a placeholder');
const saved = api.updateFields(catalog, 0, { name: ' Terminal ', command: ' foot -- nvim ~/WORK ' });
assert.strictEqual(saved.length, 1);
assert.strictEqual(saved[0].name, 'Terminal');
assert.strictEqual(saved[0].command, 'foot -- nvim ~/WORK');
assert.strictEqual(saved[0].description, '', 'optional description can stay empty');
assert.strictEqual(saved[0].icon, '󰌌', 'default icon stays intact');
const cleared = api.updateFields(saved, 0, { command: '   ' });
assert.strictEqual(cleared[0].command, '', 'blank command remains blank for validation instead of inventing a value');

const missingCommand = api.validateRequiredFields({ enabled: true, name: 'Terminal', command: '' });
assert.strictEqual(missingCommand.valid, false);
assert.strictEqual(missingCommand.missingCommand, true,
  'editing any other field must still detect a missing command');
assert.strictEqual(missingCommand.missingName, false);
const missingName = api.validateRequiredFields({ enabled: true, name: '  ', command: 'foot' });
assert.strictEqual(missingName.valid, false);
assert.strictEqual(missingName.missingName, true);
const incompleteDraft = api.validateRequiredFields({ enabled: false, name: '', command: '' });
assert.strictEqual(incompleteDraft.valid, true,
  'disabled actions may remain incomplete drafts');
JS

python3 - "$SETTINGS" "$SECTION" "$INPUT" <<'PY'
from pathlib import Path
import sys
settings, section, field = [Path(p).read_text() for p in sys.argv[1:]]
assert 'function updateLauncherCustomActionFields(index, values)' in settings
start = settings.index('function updateLauncherCustomActionFields(index, values)')
end = settings.index('function addLauncherCustomAction()', start)
assert 'SettingsLauncherActions.updateFields' in settings[start:end]
assert 'root.save()' in settings[start:end]
assert 'import "../../../js/settings/SettingsLauncherActions.js" as LauncherActions' in section
assert 'LauncherActions.validateRequiredFields({' in section
assert 'property bool validationTargetEnabled: modelData.enabled !== false' in section
assert 'property var pendingEnabledOverride: null' in section
assert 'pendingEnabledOverride === null ? modelData.enabled !== false : !!pendingEnabledOverride' in section
assert 'pendingEnabledOverride = nextEnabled' in section
assert 'pendingEnabledOverride = null' in section
assert 'validationAttempted = true' in section
assert 'validationTargetEnabled = nextEnabled' in section
assert 'if (!validation.valid)' in section
assert 'validation.missingName' in section and 'validation.missingCommand' in section
assert 'enabled: nextEnabled' in section
assert 'icon: customActionIconField.text' in section
assert 'name: actionName' in section
assert 'description: customActionDescriptionField.text' in section
assert 'command: actionCommand' in section
assert 'onToggled: customActionCard.saveAction(checked)' in section
assert section.count('onEditingFinished: customActionCard.saveAction()') == 4,     'icon, name, description, and command must all validate on commit'
assert 'onAccepted: customActionCard.saveAction()' in section
assert 'onClicked: customActionCard.saveAction()' in section
assert 'text: "Сохранить действие"' in section
assert 'placeholderText: "Название действия (обязательно)"' in section
assert 'placeholderText: "Краткое описание действия (необязательно)"' in section
assert 'placeholderText: "Команда для запуска (обязательно)' in section
assert 'краткое описание можно оставить пустым' in section
assert 'property bool validationFailed: false' in field
assert 'root.validationFailed' in field
assert '"#ff9999"' in field and '"#ff6666"' in field
assert 'Math.max(1, Config.frameBorderWidth)' in field
assert '"#ffff5c5c"' not in field
PY
printf 'launcher custom action validates required fields on every field commit with the delete-button red treatment: OK\n'
