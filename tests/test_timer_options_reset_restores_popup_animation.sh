#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'NODE'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const root = process.argv[2];
const source = fs.readFileSync(path.join(root, 'js/settings/SettingsResets.js'), 'utf8')
  .replace(/^\.pragma library\s*$/gm, '');
const context = {};
vm.runInNewContext(source + '\nthis.api = { resetTimerSettings };', context, { filename: 'SettingsResets.js' });
const config = {
  animationTimerVisibilityStyle: 'fade',
  animationTimerOptionsVisibilityStyle: 'slideLeft',
  animationTimerOptionsDuration: 200,
  timerWheelStep: 1,
  timerPresetDefaults: [5, 10]
};
const profile = {
  animationTimerVisibilityStyle: 'fade',
  animationTimerOptionsVisibilityStyle: 'fade',
  animationTimerOptionsDuration: 300,
  timerWheelStep: 2,
  timerIconOrder: 'alarm-left',
  timerPresetDefaults: [5, 10]
};
const owner = {
  activeProfile: 'Work',
  profiles: { Work: profile },
  expandedProfileData(name) { return this.profiles[name]; },
  timerPresetDefaults: [5, 10],
  timerPresets: [5, 10],
  save() { this.saved = true; }
};
context.api.resetTimerSettings(owner, config);
assert.strictEqual(config.animationTimerOptionsVisibilityStyle, 'fade', 'Timer settings reset must restore the options-window animation style');
assert.strictEqual(config.animationTimerOptionsDuration, 300, 'Timer settings reset must restore the options-window duration');
assert.strictEqual(config.timerWheelStep, 2, 'Timer settings reset continues to restore ordinary timer options');
assert.strictEqual(owner.saved, true, 'reset still persists the reset state');
console.log('Timer category reset restores options-popup animation settings: OK');
NODE
