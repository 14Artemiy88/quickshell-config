#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
MODULE="$ROOT/js/launcher/LauncherEmojiPicker.js"
LAUNCHER="$ROOT/components/launcher/Launcher.qml"

node - "$MODULE" <<'JS'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const source = fs.readFileSync(process.argv[2], 'utf8').replace(/^\.pragma library\s*/, '');
const api = vm.runInThisContext(source + '\n({ EMOJI_ENTRIES, emptyData, normalizeData, parseData, toggleFavorite, recordUsage, applyMutations, serializeData, buildResults, MAX_RECENT_EMOJIS })');
const score = (text, query) => {
  text = String(text).toLowerCase();
  query = String(query).toLowerCase();
  if (!query) return 0;
  if (text === query) return 10000;
  if (text.startsWith(query)) return 9000 - text.length;
  if (text.includes(query)) return 8000 - text.indexOf(query);
  let pos = 0;
  let result = 0;
  for (const ch of query) {
    const at = text.indexOf(ch, pos);
    if (at < 0) return -1;
    result += 100 - at;
    pos = at + 1;
  }
  return result;
};
const emoji = (value) => api.EMOJI_ENTRIES.find(entry => entry.emoji === value);
const initial = api.emptyData();
assert.deepStrictEqual(initial, { version: 1, favorites: [], usage: [] }, 'empty storage has a stable versioned shape');

let data = api.toggleFavorite(initial, '❤️');
assert(data.favorites.includes('❤️'), 'a known emoji can be favorited');
data = api.toggleFavorite(data, '❤️');
assert(!data.favorites.includes('❤️'), 'toggling an existing favorite removes it');
assert.strictEqual(api.toggleFavorite(initial, 'not-an-emoji').favorites.length, 0, 'unknown entries cannot be favorited');

data = api.toggleFavorite(data, '❤️');
data = api.recordUsage(data, '🐱', 100);
data = api.recordUsage(data, '🚀', 200);
data = api.recordUsage(data, '🐱', 300);
assert.strictEqual(data.usage.find(entry => entry.emoji === '🐱').count, 2, 'usage is counted per successful copy');
assert.strictEqual(data.usage.find(entry => entry.emoji === '🐱').lastUsed, 300, 'last-use timestamp is refreshed');
assert.strictEqual(data.usage[0].emoji, '🐱', 'usage entries are most-recent-first');

const roundTrip = api.parseData(api.serializeData(data));
assert.deepStrictEqual(roundTrip, data, 'favorites and usage survive serialization');
assert.deepStrictEqual(api.parseData('{bad json'), api.emptyData(), 'corrupt storage is ignored safely');
const sanitized = api.normalizeData({
  favorites: ['❤️', '❤️', 'ghost'],
  usage: [
    { emoji: '🐱', count: 1, lastUsed: 1 },
    { emoji: '🐱', count: 2, lastUsed: 3 },
    { emoji: 'ghost', count: 99, lastUsed: 9 }
  ]
});
assert.deepStrictEqual(sanitized.favorites, ['❤️'], 'unknown and duplicate favorites are discarded');
assert.deepStrictEqual(sanitized.usage, [{ emoji: '🐱', count: 3, lastUsed: 3 }], 'duplicate usage records are merged and unknown emoji is discarded');

const mutations = [
  { type: 'toggleFavorite', emoji: '👍' },
  { type: 'recordUsage', emoji: '👍', timestamp: 400 },
  { type: 'recordUsage', emoji: '💡', timestamp: 500 }
];
const merged = api.applyMutations(api.parseData(api.serializeData(data)), mutations);
assert(merged.favorites.includes('👍'), 'startup merge preserves early favorite toggles');
assert.strictEqual(merged.usage.find(entry => entry.emoji === '👍').count, 1, 'startup merge preserves early copy events');
assert.strictEqual(merged.usage.find(entry => entry.emoji === '💡').lastUsed, 500, 'startup merge preserves timestamped use events');

const ordered = api.buildResults('', score, 200, merged);
assert.strictEqual(ordered[0].emoji, '👍', 'favorites appear before the rest of the catalog');
assert(ordered[0].isFavorite, 'favorite metadata is exposed to the UI');
const recentNonFavorite = ordered.filter(item => item.isRecent && !item.isFavorite);
assert(recentNonFavorite.length <= api.MAX_RECENT_EMOJIS, 'recent section is bounded');
assert.strictEqual(recentNonFavorite[0].emoji, '💡', 'recently used items sort by last-use time');
assert(ordered.some(item => item.emoji === '🐱' && item.usageCount === 2), 'usage counts are attached to results');

const queried = api.buildResults('cat', score, 200, merged);
assert(queried.some(item => item.emoji === '🐱'), 'search still finds emojis with stored data');
const resultNames = api.buildResults('', score, 200, merged).map(item => item.emoji);
assert.strictEqual(new Set(resultNames).size, api.EMOJI_ENTRIES.length, 'favorites and recents do not duplicate catalog entries');
console.log('Emoji favorites, recent usage, storage validation, startup mutation merge and ordering: OK');
JS

python3 - "$LAUNCHER" <<'PY'
from pathlib import Path
import sys
source = Path(sys.argv[1]).read_text()
checks = [
    'property var emojiPickerData: LauncherEmojiPicker.emptyData()',
    'property string emojiPickerFile: Quickshell.env("HOME") + "/.cache/quickshell-launcher-emoji-data.json"',
    'function loadEmojiPickerDataFromDisk()',
    'function acceptEmojiPickerData(output)',
    'LauncherEmojiPicker.applyMutations(diskData, mutations)',
    'function persistEmojiPickerData()',
    'root.rememberLauncherEmojiUsage(root.emojiCopyPending)',
    'function toggleLauncherEmojiFavorite(value)',
    'root.toggleLauncherEmojiFavorite(appDelegate.itemData.emoji)',
    'mouse.x >= width - 48',
    'Ctrl+Shift+F toggles the selected emoji',
    'text: appDelegate.itemData && appDelegate.itemData.isFavorite ? "★" : "☆"',
    'loadEmojiPickerDataFromDisk()'
]
for item in checks:
    assert item in source, f'missing QML integration: {item}'
assert source.index('root.rememberLauncherEmojiUsage(root.emojiCopyPending)') < source.index('root.hideLauncher()', source.index('root.rememberLauncherEmojiUsage(root.emojiCopyPending)')), 'usage is recorded before launcher hide after successful copy'
print('Emoji persistence, copy tracking, favorite controls and startup wiring: OK')
PY

echo 'Launcher emoji preferences: OK'
