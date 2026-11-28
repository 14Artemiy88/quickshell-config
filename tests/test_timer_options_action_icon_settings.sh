#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
def read(rel): return (root / rel).read_text(encoding='utf-8')
def require(source, token, message):
    assert token in source, message

config = read('Config.qml')
defaults = read('js/settings/SettingsDefaults.js')
apply_core = read('js/settings/SettingsApplyCore.js')
persist = read('js/settings/SettingsPersistence.js')
resets = read('js/settings/SettingsResets.js')
settings = read('components/settings/sections/SettingsTimersSection.qml')
widget = read('components/settings/SettingsNavigationController.qml')
options = read('components/TimerOptions.qml')

ids = ['Comment', 'Duration', 'Refresh', 'Pause', 'Color']
for name in ids:
    for suffix, qtype in [('Icon', 'string'), ('IconEnabled', 'bool'), ('IconSize', 'int')]:
        key = f'timerOptions{name}{suffix}'
        require(config, f'property {qtype} {key}', f'{key} must be a Config property')
        require(defaults, f'{key}:', f'{key} must have a default value')
        require(persist, f'{key}: config.{key}', f'{key} must be persisted')
        require(resets, f'"{key}"', f'{key} must participate in profile reset')
require(config, 'property var timerOptionsActionIconOrder:', 'action icon order must be stored as a Config property')
require(defaults, 'timerOptionsActionIconOrder: ["comment", "duration", "refresh", "toggle_pause", "color"]', 'default action icon order must include manual color action')
require(persist, 'timerOptionsActionIconOrder: JSON.parse(JSON.stringify(config.timerOptionsActionIconOrder', 'action icon order must be copied safely into persisted snapshot')
require(apply_core, 'if (o.timerOptionsActionIconOrder instanceof Array)', 'saved action icon order must be normalized on load')
require(apply_core, 'Config.timerOptionsCommentIconSize = Math.max(8, Math.min(40, Math.round(tcis)))', 'comment icon size must be clamped to supported range')
require(apply_core, 'Config.timerOptionsDurationIconSize = Math.max(8, Math.min(40, Math.round(tdis)))', 'duration icon size must be clamped to supported range')
require(apply_core, 'Config.timerOptionsRefreshIconSize = Math.max(8, Math.min(40, Math.round(tris)))', 'refresh icon size must be clamped to supported range')
require(apply_core, 'Config.timerOptionsPauseIconSize = Math.max(8, Math.min(40, Math.round(tpis)))', 'pause icon size must be clamped to supported range')

for ident, name in [('comment','Comment'), ('duration','Duration'), ('refresh','Refresh'), ('toggle_pause','Pause'), ('color','Color')]:
    require(options, f'{ident}: {{ id: "{ident}", icon: Config.timerOptions{name}Icon', f'{ident} action must use a configurable glyph')
    require(options, f'enabled: Config.timerOptions{name}IconEnabled', f'{ident} action must use a configurable visibility flag')
    require(options, f'size: Config.timerOptions{name}IconSize', f'{ident} action must use a configurable icon size')
require(options, 'model: root.actionIconItems', 'popup must render the ordered enabled action list')
require(options, 'iconText: modelData.icon', 'popup glyph must be configurable')
require(options, 'iconSize: modelData.size', 'popup icon size must be configurable')
require(options, 'width: root.actionIconItems.length * 18 + Math.max(0, root.actionIconItems.length - 1) * 2', 'remaining popup icons must stay centered when actions are hidden')
require(options, 'height: Math.max(24, modelData.size + 2)', 'popup icon hit area must grow to fit larger glyphs')
require(options, 'modelData.id === "comment"', 'comment action must keep its original behavior')
require(options, 'modelData.id === "duration"', 'duration action must keep its original behavior')
require(options, 'modelData.id, root.selectedFile', 'restart/pause actions must keep their script mapping')
require(options, 'visible: root.actionIconItems.length > 0', 'empty action row must be hidden')

require(settings, 'heading: "Иконки окна опций"', 'dedicated settings frame missing')
require(settings, 'model: root.timerOptionsActionIconOrderNormalized()', 'settings rows must follow the configured action order')
require(settings, 'checked: Config[timerOptionsActionIconRow.keyPrefix + "IconEnabled"]', 'visibility toggle must bind to each action')
require(settings, 'Config[timerOptionsActionIconRow.keyPrefix + "Icon"] = text', 'icon field must edit the selected action')
require(settings, 'targetProperty: timerOptionsActionIconRow.keyPrefix + "IconSize"', 'size field must edit the selected action')
require(settings, 'function moveTimerOptionsActionIconOrderTo(iconId, destination)', 'drag destination must reorder popup icons')
require(settings, 'listRepeater: timerOptionsActionIconsRepeater', 'popup icon rows must be valid drop targets')
require(settings, 'root.moveTimerOptionsActionIconOrderTo(modelData, toIndex)', 'drag drop must commit the selected destination')
require(settings, 'keys: ["timerOptionsActionIconOrder"]', 'frame dirty tracking must include action order')
require(widget, 'keys: ["timerOptionsActionIconOrder", "animationTimerOptionsVisibilityStyle", "animationTimerOptionsVisibilityProfile", "animationTimerOptionsDuration"]', 'timer options subtab dirty tracking must include icon order')

# Verify all action IDs are included in timer-module profile and reset paths.
for name in ids:
    require(resets, f'"timerOptions{name}IconEnabled"', f'{name} visibility must participate in timer-module profile restore')
print('Timer options action icon visibility/glyph/size/order, popup wiring, persistence, profile reset and UI: OK')
PY

echo 'Timer options action icon settings: OK'

node - "$ROOT" <<'JS'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const root = process.argv[2];
const source = fs.readFileSync(path.join(root, 'js/settings/SettingsApplyCore.js'), 'utf8')
  .replace(/^\.pragma library\s*$/gm, '')
  .replace(/^\.import .*$/gm, '');
const context = { Schema: {} };
vm.createContext(context);
vm.runInContext(source, context, { filename: 'SettingsApplyCore.js' });
const config = {};
context.apply({}, config, {
  timerOptionsCommentIcon: 'C',
  timerOptionsCommentIconEnabled: false,
  timerOptionsCommentIconSize: 77,
  timerOptionsDurationIcon: 'D',
  timerOptionsDurationIconEnabled: true,
  timerOptionsDurationIconSize: 5,
  timerOptionsRefreshIcon: 'R',
  timerOptionsRefreshIconEnabled: false,
  timerOptionsRefreshIconSize: 18,
  timerOptionsPauseIcon: 'P',
  timerOptionsPauseIconEnabled: true,
  timerOptionsPauseIconSize: 24,
  timerOptionsColorIcon: 'K',
  timerOptionsColorIconEnabled: true,
  timerOptionsColorIconSize: 27,
  timerOptionsActionIconOrder: vm.runInContext("['color', 'duration', 'duration', 'unknown']", context)
});
assert.strictEqual(config.timerOptionsCommentIcon, 'C');
assert.strictEqual(config.timerOptionsCommentIconEnabled, false);
assert.strictEqual(config.timerOptionsCommentIconSize, 40, 'sizes clamp to upper limit');
assert.strictEqual(config.timerOptionsDurationIcon, 'D');
assert.strictEqual(config.timerOptionsDurationIconEnabled, true);
assert.strictEqual(config.timerOptionsDurationIconSize, 8, 'sizes clamp to lower limit');
assert.strictEqual(config.timerOptionsRefreshIcon, 'R');
assert.strictEqual(config.timerOptionsRefreshIconEnabled, false);
assert.strictEqual(config.timerOptionsPauseIcon, 'P');
assert.strictEqual(config.timerOptionsPauseIconEnabled, true);
assert.strictEqual(config.timerOptionsColorIcon, 'K');
assert.strictEqual(config.timerOptionsColorIconEnabled, true);
assert.strictEqual(config.timerOptionsColorIconSize, 27);
assert.strictEqual(config.timerOptionsColorIcon, 'K');
assert.strictEqual(config.timerOptionsColorIconEnabled, true);
assert.strictEqual(config.timerOptionsColorIconSize, 27);
assert.deepStrictEqual(Array.from(config.timerOptionsActionIconOrder), ['color', 'duration', 'comment', 'refresh', 'toggle_pause'], 'order de-duplicates unknown IDs and appends missing actions');
console.log('Timer options action icon settings loader normalization and size bounds: OK');
JS
