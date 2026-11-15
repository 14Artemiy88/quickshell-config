#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'JS'
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const assert = require('assert');
const root = process.argv[2];
const source = fs.readFileSync(path.join(root, 'js/settings/SettingsThemeManager.js'), 'utf8')
  .replace(/^\.pragma library\s*/m, '')
  .replace(/^\.import .*$/mg, '');
const context = {Profiles: {}};
vm.createContext(context);
vm.runInContext(source, context);
const manager = context;
const themes = {palette(name) {
  return name === 'A'
    ? {accent:'#111111', settingsBackground:'#aa000000', playerProgressTrack:'#111111', playerProgressFill:'#222222', topAppsCpuBarColor:'#333333', topAppsRamBarColor:'#444444', topAppsCpuBarTrackColor:'#555555', topAppsRamBarTrackColor:'#666666', cpu1Track:'#101010', cpu8Track:'#181818'}
    : {accent:'#eeeeee', settingsBackground:'#bb000000', playerProgressTrack:'#eeeeee', playerProgressFill:'#dddddd', topAppsCpuBarColor:'#cccccc', topAppsRamBarColor:'#bbbbbb', topAppsCpuBarTrackColor:'#aaaaaa', topAppsRamBarTrackColor:'#999999', cpu1Track:'#202020', cpu8Track:'#282828'};
}};
const independent = {
  settingsBackground:'#e6123456', playerProgressTrack:'#7f123456', playerProgressFill:'#ffabcdef',
  topAppsCpuBarColor:'#ff010203', topAppsRamBarColor:'#ff040506',
  topAppsCpuBarTrackColor:'#7f070809', topAppsRamBarTrackColor:'#7f0a0b0c',
};
const config = {...independent, accent:'#000000'};
const owner = {customThemes:{}, save(){}};
manager.applyTheme(owner, themes, config, 'B');
assert.strictEqual(config.accent, '#eeeeee', 'theme-managed accent still changes');
assert.strictEqual(config.cpu1Track, '#202020', 'CPU 1 inactive track follows selected theme');
assert.strictEqual(config.cpu8Track, '#282828', 'CPU 8 inactive track follows selected theme');
for (const [key, value] of Object.entries(independent))
  assert.strictEqual(config[key], value, `${key} must remain independent from theme switching`);
manager.applyTheme(owner, themes, config, 'A');
assert.strictEqual(config.cpu1Track, '#101010', 'CPU 1 inactive track changes with theme');
assert.strictEqual(config.cpu8Track, '#181818', 'CPU 8 inactive track changes with theme');
for (const [key, value] of Object.entries(independent))
  assert.strictEqual(config[key], value, `${key} must remain stable across repeated theme switches`);
console.log('Theme switching preserves independent settings/player/Top Apps colors: OK');
JS
