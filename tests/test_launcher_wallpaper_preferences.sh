#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
MODULE="$ROOT/js/launcher/LauncherWallpaperPicker.js"
LAUNCHER="$ROOT/components/launcher/Launcher.qml"

node - "$MODULE" "$LAUNCHER" <<'JS'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const modulePath = process.argv[2];
const launcherPath = process.argv[3];
const source = fs.readFileSync(modulePath, 'utf8').replace(/^\.pragma library\s*/, '');
const api = vm.runInThisContext(source + '\n({ emptyData, normalizeData, parseData, serializeData, toggleFavorite, recordUsage, applyMutations, isFavorite, recentUsageForScreen, parseQuery, buildResults, emptyStateMessage, MAX_WALLPAPER_USAGE, MAX_RECENT_WALLPAPERS })');
const entries = [
  { path: '/wallpapers/amber.jpg', name: 'amber.jpg' },
  { path: '/wallpapers/blue.png', name: 'blue.png' },
  { path: '/wallpapers/forest.webp', name: 'forest.webp' },
  { path: '/wallpapers/night.png', name: 'night.png' },
  { path: '/wallpapers/sunrise.jpg', name: 'sunrise.jpg' }
];

assert.deepStrictEqual(api.emptyData(), { version: 1, favorites: [], usage: [] }, 'new wallpaper preference data has an explicit version and empty lists');
assert.deepStrictEqual(api.parseData('{invalid'), api.emptyData(), 'corrupted data safely resets to an empty value');

let data = api.toggleFavorite(api.emptyData(), '/wallpapers/blue.png');
assert(api.isFavorite(data, '/wallpapers/blue.png'), 'favorite toggle adds a supported image path');
data = api.toggleFavorite(data, '/wallpapers/amber.jpg');
assert.deepStrictEqual(data.favorites, ['/wallpapers/amber.jpg', '/wallpapers/blue.png'], 'new favorite is placed first');
data = api.toggleFavorite(data, '/wallpapers/blue.png');
assert(!api.isFavorite(data, '/wallpapers/blue.png'), 'favorite toggle removes an existing entry');
assert.deepStrictEqual(api.toggleFavorite(data, '/wallpapers/'), data, 'invalid directory paths are ignored');

let usage = api.recordUsage(data, '/wallpapers/amber.jpg', 'DP-1', 1000);
usage = api.recordUsage(usage, '/wallpapers/blue.png', 'DP-1', 2000);
usage = api.recordUsage(usage, '/wallpapers/amber.jpg', 'DP-1', 3000);
usage = api.recordUsage(usage, '/wallpapers/forest.webp', 'HDMI-A-1', 4000);
assert.strictEqual(usage.usage.find(x => x.path === '/wallpapers/amber.jpg' && x.screenName === 'DP-1').count, 2, 'repeated apply increments count per output');
assert.strictEqual(usage.usage.find(x => x.path === '/wallpapers/amber.jpg' && x.screenName === 'DP-1').lastUsed, 3000, 'repeated apply updates last-used timestamp');
assert.deepStrictEqual(api.recentUsageForScreen(usage, 'DP-1').map(x => x.path), ['/wallpapers/amber.jpg', '/wallpapers/blue.png'], 'recent history is isolated by monitor');
assert.deepStrictEqual(api.recentUsageForScreen(usage, 'hdmi-a-1').map(x => x.path), ['/wallpapers/forest.webp'], 'output name matching is case-insensitive');
assert.deepStrictEqual(api.recentUsageForScreen(usage, 'DP-2'), [], 'other monitors do not inherit a screen history');
let cappedRecent = api.emptyData();
for (let i = 0; i < 20; ++i)
  cappedRecent = api.recordUsage(cappedRecent, `/wallpapers/recent-${i}.jpg`, 'DP-1', 10000 + i);
assert.strictEqual(api.recentUsageForScreen(cappedRecent, 'DP-1').length, api.MAX_RECENT_WALLPAPERS, 'recent list is capped to the latest twelve entries per output');
assert(cappedRecent.usage.length <= api.MAX_WALLPAPER_USAGE, 'persistent usage data has a bounded size');

const mutations = [
  { type: 'toggleFavorite', path: '/wallpapers/sunrise.jpg' },
  { type: 'recordUsage', path: '/wallpapers/night.png', screenName: 'DP-2', timestamp: 5000 }
];
const merged = api.applyMutations(usage, mutations);
assert(api.isFavorite(merged, '/wallpapers/sunrise.jpg'), 'async load mutations retain early favorite toggles');
assert(api.recentUsageForScreen(merged, 'DP-2').some(x => x.path === '/wallpapers/night.png'), 'async load mutations retain early successful wallpaper applies');
assert.deepStrictEqual(api.parseData(api.serializeData(merged)), merged, 'data round-trips through persistent JSON');
assert(api.parseData(JSON.stringify({ version: 1, favorites: ['/wallpapers/x.jpg', '/', 'relative.png'], usage: [{ path: '/wallpapers/y.png', screenName: 'DP-1', count: 1, lastUsed: 123 }] })).favorites.length === 1, 'legacy/corrupt paths are filtered while valid history survives');

const score = (text, query) => String(text).toLowerCase().includes(String(query).toLowerCase()) ? 100 : -1;
const favoriteData = api.toggleFavorite(api.emptyData(), '/wallpapers/forest.webp');
let applied = api.recordUsage(favoriteData, '/wallpapers/blue.png', 'DP-1', 2000);
applied = api.recordUsage(applied, '/wallpapers/amber.jpg', 'DP-1', 3000);
applied = api.recordUsage(applied, '/wallpapers/night.png', 'HDMI-A-1', 4000);
const all = api.buildResults('', entries, score, 200, applied, 'all', 'DP-1');
assert.deepStrictEqual(all.slice(0, 3).map(x => x.path), ['/wallpapers/forest.webp', '/wallpapers/amber.jpg', '/wallpapers/blue.png'], 'all view orders favorites, selected-screen recents, then the remaining catalogue');
assert.strictEqual(all[0].isFavorite, true, 'catalog result exposes favorite state for the star overlay');
assert.strictEqual(all[1].usageCount, 1, 'catalog result exposes usage metadata');
const favorites = api.buildResults('', entries, score, 200, applied, 'favorites', 'DP-1');
assert.deepStrictEqual(favorites.map(x => x.path), ['/wallpapers/forest.webp'], 'favorite scope only returns favorite paths present in the current folder');
const recent = api.buildResults('', entries, score, 200, applied, 'recent', 'DP-1');
assert.deepStrictEqual(recent.map(x => x.path), ['/wallpapers/amber.jpg', '/wallpapers/blue.png'], 'recent scope shows only recent items for the selected screen');
const searchedRecent = api.buildResults('blue', entries, score, 200, applied, 'recent', 'DP-1');
assert.deepStrictEqual(searchedRecent.map(x => x.path), ['/wallpapers/blue.png'], 'search terms filter within the recent scope');
assert.deepStrictEqual(api.buildResults('', entries, score, 200, applied, 'recent', 'HDMI-A-1').map(x => x.path), ['/wallpapers/night.png'], 'selecting another output changes the recent subset only');
assert.strictEqual(api.buildResults('sunrise', entries, score, 200, applied, 'favorites', 'DP-1').length, 0, 'scoped search does not leak non-favorites');
assert(api.emptyStateMessage(false, '', '/wallpapers', 5, '', 'favorites').toLowerCase().includes('избранных'), 'favorite view has a dedicated empty state');
assert(api.emptyStateMessage(false, '', '/wallpapers', 5, '', 'recent', 'DP-2').includes('DP-2'), 'recent view empty state names the selected output');

const qAll = api.parseQuery('wallpaper');
const qFav = api.parseQuery('wallpaper favorites sunset');
const qRecent = api.parseQuery('обои недавние forest');
assert.strictEqual(qAll.scope, 'all', 'base picker uses the complete catalog');
assert.deepStrictEqual({ scope: qFav.scope, query: qFav.query }, { scope: 'favorites', query: 'sunset' }, 'favorite command accepts an appended search term');
assert.deepStrictEqual({ scope: qRecent.scope, query: qRecent.query }, { scope: 'recent', query: 'forest' }, 'Russian recent command accepts an appended search term');

const launcher = fs.readFileSync(launcherPath, 'utf8');
assert(launcher.includes('wallpaperPickerFile: Quickshell.env("HOME") + "/.cache/quickshell-launcher-wallpaper-data.json"'), 'wallpaper state lives outside active settings profiles');
assert(launcher.includes('loadWallpaperPickerDataFromDisk()'), 'wallpaper preferences load on launcher startup');
assert(launcher.includes('root.wallpaperPickerData,\n                wallpaperQuery.scope,\n                root.wallpaperSelectedScreenName'), 'active scope uses the selected monitor and persistent state');
assert(launcher.includes('root.rememberWallpaperUsage(root.wallpaperApplyPendingPath, root.wallpaperApplyPendingScreenName)'), 'usage is recorded only after wallpaper backend returns success');
assert(launcher.includes('root.toggleWallpaperFavorite(appDelegate.itemData.path)'), 'tile star toggles favorite without applying an image');
assert(launcher.includes('>wallpaper favorites') && launcher.includes('>wallpaper recent'), 'toolbar exposes favorite and recent scopes');
assert(launcher.includes('__LAUNCHER_WALLPAPER_DATA_REQUEST__'), 'asynchronous load carries a generation marker');
assert(launcher.includes('root.wallpaperPickerPendingMutations'), 'early mutations are merged after asynchronous data load');
assert(launcher.includes('root.wallpaperPickerWriteQueuedPayload'), 'writes are serialized latest-snapshot-wins');
assert(launcher.includes('loadWallpaperPickerDataFromDisk()'), 'persistent wallpaper data is loaded at startup');
assert(launcher.includes('property string wallpaperPickerFile: Quickshell.env("HOME") + "/.cache/quickshell-launcher-wallpaper-data.json"'), 'wallpaper data is stored outside profiles');
assert(launcher.includes('mouse.x >= width - 46 && mouse.y <= 46'), 'star hit area does not trigger the tile apply action');
assert(launcher.includes('wallpaperQuery.scope') && launcher.includes('root.wallpaperSelectedScreenName'), 'recent scope is bound to the selected monitor');
console.log('Wallpaper favorites, per-monitor recents, scoped queries and async persistence: OK');
JS

echo 'Launcher wallpaper preferences: OK'
