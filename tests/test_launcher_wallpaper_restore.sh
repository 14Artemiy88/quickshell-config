#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
LAUNCHER="$ROOT/components/launcher/Launcher.qml"
MODULE="$ROOT/js/launcher/LauncherWallpaperPicker.js"

node - "$LAUNCHER" "$MODULE" <<'JS'
const fs = require('fs');
const assert = require('assert');
const launcher = fs.readFileSync(process.argv[2], 'utf8');
const picker = fs.readFileSync(process.argv[3], 'utf8');

const readIndex = launcher.indexOf('function acceptWallpaperPickerData(output)');
const readEnd = launcher.indexOf('function loadWallpaperPickerDataFromDisk()', readIndex);
assert(readIndex >= 0 && readEnd > readIndex, 'wallpaper data acceptance remains a standalone startup step');
const loadBlock = launcher.slice(readIndex, readEnd);
assert(loadBlock.includes('root.scheduleWallpaperRestore()'), 'restoration is scheduled only after current persisted data and startup mutations are merged');

const restoreIndex = launcher.indexOf('function scheduleWallpaperRestore()');
const restoreEnd = launcher.indexOf('property var appsUnifiedResults:', restoreIndex);
assert(restoreIndex >= 0 && restoreEnd > restoreIndex, 'startup restoration helpers are grouped with wallpaper preference behavior');
const restoreBlock = launcher.slice(restoreIndex, restoreEnd);
for (const token of [
  'root.wallpaperRestoreStarted',
  'LauncherWallpaperPicker.appliedWallpapers(root.wallpaperPickerData)',
  'root.wallpaperScreenIndex(candidate.screenName)',
  'root.wallpaperApplyIsRestore = true',
  'root.wallpaperRestoreQueue',
  'root.wallpaperManualPendingApply',
  'attempts < 2'
]) {
  assert(restoreBlock.includes(token), `startup restore includes ${token}`);
}
assert(restoreBlock.includes('Quickshell.screens.length === 0'), 'restore waits briefly for the compositor to expose screens');
assert(restoreBlock.includes('wallpaperRestoreTimer.restart()'), 'restore retries asynchronously rather than blocking shell startup');

const processIndex = launcher.indexOf('id: wallpaperApplyProcess');
const processEnd = launcher.indexOf('\n    Process {', processIndex + 1);
const processBlock = launcher.slice(processIndex, processEnd);
assert(processBlock.includes('if (root.wallpaperApplyIsRestore) {\n                root.finishWallpaperRestore(exitCode)\n                return'), 'restore completion is separated from manual selection behavior');
assert(processBlock.includes('root.rememberWallpaperUsage('), 'manual selection history is only recorded in the non-restore branch');
assert(launcher.includes('new manual choice must win over a queued startup restore'), 'manual selections take precedence over startup restore targets');
assert(launcher.includes('root.wallpaperRestoreQueue = root.wallpaperRestoreQueue.filter(function(item)'), 'manual choices remove stale restore targets for that output');
assert(processBlock.includes('root.hideLauncher()'), 'startup restore does not hide or open the Launcher');

assert(picker.includes('function recordSuccessfulApply('), 'picker model persists successful selected wallpapers');
assert(picker.includes('function appliedWallpapers(value)'), 'picker model exposes normalized restore targets');
assert(picker.includes('Older v1 files have no `applied` field'), 'existing v1411 data is migrated from successful per-monitor usage history');

console.log('Launcher per-monitor wallpaper restoration: startup loading, v1411 migration, async serialized apply and non-interactive completion: OK');
JS
