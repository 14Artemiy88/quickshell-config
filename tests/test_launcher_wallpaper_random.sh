#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODULE="$ROOT/js/launcher/LauncherWallpaperPicker.js"
LAUNCHER="$ROOT/components/launcher/Launcher.qml"

node - "$MODULE" <<'JS'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const source = fs.readFileSync(process.argv[2], 'utf8').replace(/^\.pragma library\s*/, '');
const api = vm.runInThisContext(source + '\n({ parseQuery, emptyData, recordUsage, chooseRandomEntry, buildResults, MAX_WALLPAPERS })');

assert.deepStrictEqual(api.parseQuery('wallpaper random'), {
  active: true, query: '', scope: 'all', random: true
}, 'random mode is parsed as a dedicated wallpaper command');
assert.deepStrictEqual(api.parseQuery('wallpaper shuffle forest'), {
  active: true, query: 'forest', scope: 'all', random: true
}, 'shuffle alias keeps an optional filter query');
assert.deepStrictEqual(api.parseQuery('обои случайно лес'), {
  active: true, query: 'лес', scope: 'all', random: true
}, 'Russian random alias keeps an optional filter query');
assert.deepStrictEqual(api.parseQuery('wallpaper favorites'), {
  active: true, query: '', scope: 'favorites'
}, 'existing favorites query shape and behavior remain unchanged');
assert.deepStrictEqual(api.parseQuery('wallpaper recent sunset'), {
  active: true, query: 'sunset', scope: 'recent'
}, 'existing recent query shape and behavior remain unchanged');
assert.deepStrictEqual(api.parseQuery('random'), { active: false, query: '', scope: 'all' }, 'random keyword outside the wallpaper prefix is not intercepted');

const entries = [
  { path: '/wallpapers/a.jpg', name: 'a.jpg' },
  { path: '/wallpapers/b.jpg', name: 'b.jpg' },
  { path: '/wallpapers/c.jpg', name: 'c.jpg' }
];
let data = api.emptyData();
data = api.recordUsage(data, '/wallpapers/b.jpg', 'DP-1', 100);
const first = api.chooseRandomEntry(entries, data, 'DP-1', 0);
assert.strictEqual(first.path, '/wallpapers/a.jpg', 'random selection excludes the last applied image on the same monitor');
const last = api.chooseRandomEntry(entries, data, 'DP-1', 0.999999);
assert.strictEqual(last.path, '/wallpapers/c.jpg', 'random fraction selects deterministically within the eligible set');
const otherScreen = api.chooseRandomEntry(entries, data, 'HDMI-A-1', 0);
assert.strictEqual(otherScreen.path, '/wallpapers/a.jpg', 'one monitor history does not affect another monitor');
const onlyOne = api.chooseRandomEntry([entries[1]], data, 'DP-1', 0.5);
assert.strictEqual(onlyOne.path, '/wallpapers/b.jpg', 'the current image remains eligible when it is the only available image');
assert.strictEqual(api.chooseRandomEntry([], data, 'DP-1', 0), null, 'empty catalog has no random selection');
assert.strictEqual(api.chooseRandomEntry([{ path: '/wallpapers/readme.txt' }], data, 'DP-1', 0), null, 'unsupported files cannot be selected');

const score = (text, query) => String(text).toLowerCase().includes(String(query).toLowerCase()) ? 1 : -1;
const filtered = api.buildResults('forest', [
  { path: '/wallpapers/forest.jpg', name: 'forest.jpg' },
  { path: '/wallpapers/ocean.jpg', name: 'ocean.jpg' }
], score, api.MAX_WALLPAPERS);
assert.deepStrictEqual(filtered.map(item => item.path), ['/wallpapers/forest.jpg'], 'random selection can be restricted to ordinary wallpaper search matches');
console.log('Wallpaper random mode parsing, per-monitor no-repeat selection, single-image fallback and filtering: OK');
JS

python3 - "$LAUNCHER" <<'PY'
from pathlib import Path
import sys
source = Path(sys.argv[1]).read_text(encoding='utf-8')
checks = {
    'random mode flag is derived from the shared wallpaper query parser': 'readonly property bool wallpaperRandomMode: root.activeWallpaperQuery.active' in source,
    'random selection uses the existing wallpaper catalog and per-monitor history': 'LauncherWallpaperPicker.chooseRandomEntry(' in source and 'root.wallpaperPickerData' in source and 'root.wallpaperSelectedScreenName' in source,
    'selected wallpaper is applied through the existing per-monitor backend': 'root.applyWallpaper(selected.path)' in source,
    'random command result has dedicated presentation metadata': 'kind: "wallpaperRandomAction"' in source and 'case "wallpaperRandomAction"' in source,
    'only available random results trigger an apply': 'if (result.available === true)' in source and 'root.applyRandomWallpaper()' in source,
    'random action has a shuffle fallback icon rather than the palette icon': 'text: appDelegate.itemData.kind === \"wallpaperRandomAction\" ? \"\" : \"󰏘\"' in source,
    'wallpaper grid keeps its compact action-row geometry in random mode': 'root.wallpaperPickerActive && !root.wallpaperRandomMode ? width / wallpaperColumnCount : width' in source,
    'normal wallpaper tile geometry remains intact for the ordinary picker': 'root.wallpaperPickerActive && !root.wallpaperRandomMode ? appList.wallpaperTileWidth : appList.width' in source,
    'catalog loading is already shared with all wallpaper queries': 'if (wallpaperQuery.active) {\n                            root.loadWallpaperCatalog(false)' in source,
}
for label, ok in checks.items():
    assert ok, label
print('Launcher random wallpaper action, safe availability gating and shared per-monitor apply path: OK')
PY
