#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root=Path(sys.argv[1])
def read(name): return (root/name).read_text(encoding='utf-8')
def require(src, token, message): assert token in src, message

config=read('Config.qml'); defaults=read('js/settings/SettingsDefaults.js')
persist=read('js/settings/SettingsPersistence.js'); resets=read('js/settings/SettingsResets.js')
apply=read('js/settings/SettingsApplyCore.js'); schema=read('js/settings/SettingsSchema.js')
settings=read('components/settings/sections/SettingsTimersSection.qml')
widget=read('components/settings/SettingsWidget.qml'); options=read('components/TimerOptions.qml')
shell=read('shell.qml'); timer=read('scripts/timer'); actions=read('scripts/timer.d/actions.sh')
common=read('scripts/timer.d/common.sh'); timer_widget=read('components/TimerWidget.qml')

for key, qtype in [('timerOptionsColorIcon','string'),('timerOptionsColorIconEnabled','bool'),('timerOptionsColorIconSize','int'),('timerRandomColorMode','string'),('timerRandomColorMin','color'),('timerRandomColorMax','color')]:
    require(config, f'property {qtype} {key}', f'{key} Config declaration missing')
    require(defaults, f'{key}:', f'{key} default missing')
    require(persist, f'{key}:', f'{key} persistence missing')
    require(resets, f'"{key}"', f'{key} reset/profile scope missing')
require(defaults, 'timerRandomColorMode: "full"', 'black-to-white full mode must be default')
require(defaults, 'timerRandomColorMin: "#000000"', 'default minimum endpoint must be black')
require(defaults, 'timerRandomColorMax: "#ffffff"', 'default maximum endpoint must be white')
require(apply, '["full", "light", "dark", "custom"]', 'random color modes must be normalized')
require(schema, 'p.timerRandomColorMin = normalizeSavedColor', 'custom minimum color must be normalized for profiles')
require(schema, 'p.timerRandomColorMax = normalizeSavedColor', 'custom maximum color must be normalized for profiles')
require(settings, 'heading: "Случайные цвета таймеров"', 'random color settings frame missing')
for label in ['Полный · чёрный–белый','Только светлые','Только тёмные','Пользовательский']:
    require(settings, label, f'random range option missing: {label}')
require(settings, 'targetProperty: "timerRandomColorMin"', 'minimum color field missing')
require(settings, 'targetProperty: "timerRandomColorMax"', 'maximum color field missing')
require(widget, '"timerRandomColorMode", "timerRandomColorMin", "timerRandomColorMax"', 'random color settings dirty tracking missing')

require(options, 'color: { id: "color", icon: Config.timerOptionsColorIcon', 'color action glyph configuration missing')
require(options, 'function openColorEditor()', 'manual timer color editor not wired')
require(options, 'function saveColor()', 'manual color save missing')
require(options, '"set_color"', 'manual color action does not use timer script')
require(options, 'visible: root.colorMode', 'manual color editor overlay missing')
require(shell, 'timerOptionsPopup.colorMode', 'overlay keyboard focus missing for color editor')
require(actions, 'set_color_locked()', 'serialized manual color action missing')
require(timer, 'set_color)     set_color', 'timer CLI command missing')
require(common, 'light) min_hex="808080"; max_hex="ffffff"', 'light-only random range must use upper half')
require(common, 'dark) min_hex="000000"; max_hex="7f7f7f"', 'dark-only random range must use lower half')
require(timer_widget, '"update_color", timerData.file, Config.timerRandomColorMode', 'right-click reroll must use configured random range')
require(timer_widget, '"add", String(modelData), "", Config.timerRandomColorMode', 'new timers must use configured random range')
print('Timer color editor, action icon, random ranges, persistence/profile/reset and UI wiring: OK')
PY

node - "$ROOT" <<'JS'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const root = process.argv[2];
const source = fs.readFileSync(path.join(root, 'js/settings/SettingsApplyCore.js'), 'utf8')
  .replace(/^\.pragma library\s*$/gm, '')
  .replace(/^\.import .*$/gm, '');
const context = {
  Schema: {
    normalizeSavedColor(value, fallback) {
      const text = String(value ?? '').trim();
      return /^#[0-9a-fA-F]{6}$/.test(text) ? text.toLowerCase() : fallback;
    }
  }
};
vm.createContext(context);
vm.runInContext(source, context, { filename: 'SettingsApplyCore.js' });
const config = {};
context.apply({}, config, {
  timerRandomColorMode: 'custom',
  timerRandomColorMin: '#123456',
  timerRandomColorMax: '#ABCDEF',
  timerOptionsColorIcon: 'K',
  timerOptionsColorIconEnabled: false,
  timerOptionsColorIconSize: 80,
  timerOptionsActionIconOrder: vm.runInContext("['color', 'duration']", context)
});
assert.strictEqual(config.timerRandomColorMode, 'custom');
assert.strictEqual(config.timerRandomColorMin, '#123456');
assert.strictEqual(config.timerRandomColorMax, '#abcdef');
assert.strictEqual(config.timerOptionsColorIcon, 'K');
assert.strictEqual(config.timerOptionsColorIconEnabled, false);
assert.strictEqual(config.timerOptionsColorIconSize, 40);
assert.deepStrictEqual(Array.from(config.timerOptionsActionIconOrder), ['color', 'duration', 'comment', 'refresh', 'toggle_pause']);
context.apply({}, config, { timerRandomColorMode: 'bogus', timerRandomColorMin: 'red', timerRandomColorMax: '#ffffff' });
assert.strictEqual(config.timerRandomColorMode, 'full', 'unknown color mode must fall back to full spectrum');
assert.strictEqual(config.timerRandomColorMin, '#000000', 'invalid minimum endpoint must fall back to black');
console.log('Timer random color settings loader, validation and defaults: OK');
JS
