#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT/js/launcher/LauncherSelection.js" "$ROOT/js/launcher/LauncherWallpaperPicker.js" "$ROOT/components/launcher/Launcher.qml" <<'JS'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
function load(path, exports) {
  const source = fs.readFileSync(path, 'utf8').replace(/^\.pragma library\s*/, '');
  return vm.runInThisContext(source + `\n({ ${exports.join(', ')} })`);
}
const selection = load(process.argv[2], ['moveLinearIndex']);
assert.strictEqual(selection.moveLinearIndex(0, -1, 5), 4, 'Up from the first item wraps to the last');
assert.strictEqual(selection.moveLinearIndex(4, 1, 5), 0, 'Down from the last item wraps to the first');
assert.strictEqual(selection.moveLinearIndex(2, 1, 5), 3, 'middle Down moves by one');
assert.strictEqual(selection.moveLinearIndex(2, -1, 5), 1, 'middle Up moves by one');
assert.strictEqual(selection.moveLinearIndex(-1, 1, 5), 0, 'unset selection starts at the first item');
assert.strictEqual(selection.moveLinearIndex(-1, -1, 5), 0, 'unset selection remains compatible when navigating Up');
assert.strictEqual(selection.moveLinearIndex(0, -1, 1), 0, 'one item remains selected');
assert.strictEqual(selection.moveLinearIndex(0, 1, 0), -1, 'empty lists stay unselected');
const wallpaper = load(process.argv[3], ['moveGridIndex']);
assert.strictEqual(wallpaper.moveGridIndex(0, 'up', 3, 9), 6, 'wallpaper grid wraps Up to the bottom row in the same column');
assert.strictEqual(wallpaper.moveGridIndex(6, 'down', 3, 9), 0, 'wallpaper grid wraps Down to the top row in the same column');
assert.strictEqual(wallpaper.moveGridIndex(2, 'up', 3, 10), 9, 'partial last row clamps the column when wrapping');
assert.strictEqual(wallpaper.moveGridIndex(9, 'down', 3, 10), 0, 'partial last row wraps Down to the first row');
assert.strictEqual(wallpaper.moveGridIndex(0, 'left', 3, 9), 0, 'horizontal movement still stays within its row');
assert.strictEqual(wallpaper.moveGridIndex(2, 'right', 3, 9), 2, 'horizontal movement does not wrap across rows');
const launcher = fs.readFileSync(process.argv[4], 'utf8');
for (const mode of ['appList', 'runList', 'networkList', 'nixList', 'passList', 'clipboardList', 'projectList', 'powerList']) {
  assert(launcher.includes(`LauncherSelection.moveLinearIndex(${mode}.currentIndex, 1, ${mode}.count)`), `${mode} Down uses cyclic selection`);
  assert(launcher.includes(`LauncherSelection.moveLinearIndex(${mode}.currentIndex, -1, ${mode}.count)`), `${mode} Up uses cyclic selection`);
}
assert(launcher.includes('LauncherSelection.moveLinearIndex(\n            windowList.currentIndex, direction, count\n        )'), 'window selection uses cyclic selection');
console.log('Launcher cyclic list and wallpaper-grid navigation: OK');
JS
