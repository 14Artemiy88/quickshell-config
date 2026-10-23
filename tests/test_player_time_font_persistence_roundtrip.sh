#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'JS'
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const assert = require('assert');
const root = process.argv[2];
const source = fs.readFileSync(path.join(root, 'js/settings/SettingsApplyTimerPlayer.js'), 'utf8')
  .replace(/^\.pragma library\s*/m, '')
  .replace(/^\.import .*$/mg, '');
const context = {};
vm.createContext(context);
vm.runInContext(source, context, {filename:'SettingsApplyTimerPlayer.js'});
const persistence = fs.readFileSync(path.join(root, 'js/settings/SettingsPersistence.js'), 'utf8');
assert.match(persistence, /playerTimeFont\s*:\s*config\.playerTimeFont/, 'custom font is included in saved settings payload');
const config = {playerTimeFont:'Ubuntu Mono Nerd Font', playerTimeFontSize:11};

// Simulate settings.json moved to another installation.
context.apply(config, {playerTimeFont:'Inter', playerTimeFontSize:17}, false);
assert.strictEqual(config.playerTimeFont, 'Inter', 'custom Player time font restores from persisted settings');
assert.strictEqual(config.playerTimeFontSize, 17, 'numeric Player settings still restore');

context.apply(config, {playerTimeFont:'  Noto Sans Mono  '}, false);
assert.strictEqual(config.playerTimeFont, 'Noto Sans Mono', 'font value trims surrounding whitespace');
context.apply(config, {playerTimeFont:'   '}, false);
assert.strictEqual(config.playerTimeFont, 'Noto Sans Mono', 'empty legacy font does not erase valid current value');
context.apply(config, {playerTimeFontSize:12}, false);
assert.strictEqual(config.playerTimeFont, 'Noto Sans Mono', 'missing legacy field keeps active font');
console.log('Player time-font persistence round-trip: OK');
JS
