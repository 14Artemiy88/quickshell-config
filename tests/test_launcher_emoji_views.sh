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
const api = vm.runInThisContext(source + '\n({ EMOJI_ENTRIES, emptyData, parseQuery, buildResults, recordUsage, toggleFavorite, emptyStateMessage, MAX_RECENT_EMOJIS })');
const score = (text, query) => {
  text = String(text).toLowerCase();
  query = String(query).toLowerCase();
  if (!query) return 0;
  if (text === query) return 10000;
  if (text.startsWith(query)) return 9000 - text.length;
  if (text.includes(query)) return 8000 - text.indexOf(query);
  let pos = 0, value = 0;
  for (const ch of query) {
    const at = text.indexOf(ch, pos);
    if (at < 0) return -1;
    value += 100 - at;
    pos = at + 1;
  }
  return value;
};

const favoriteAliases = ['favorites', 'favorite', 'fav', 'starred', 'избранное', 'избранные'];
for (const alias of favoriteAliases) {
  const parsed = api.parseQuery(`emoji ${alias}`);
  assert.strictEqual(parsed.active, true, `${alias} activates the picker`);
  assert.strictEqual(parsed.scope, 'favorites', `${alias} selects favorites`);
  assert.strictEqual(parsed.query, '', `${alias} leaves no residual search`);
}
const recentAliases = ['recent', 'recents', 'recently', 'history', 'used', 'недавние', 'последние', 'история'];
for (const alias of recentAliases) {
  const parsed = api.parseQuery(`emoji ${alias}`);
  assert.strictEqual(parsed.scope, 'recent', `${alias} selects recents`);
}
assert.deepStrictEqual(api.parseQuery('emoji favorites heart'), { active: true, query: 'heart', scope: 'favorites' }, 'search can be narrowed within favorites');
assert.deepStrictEqual(api.parseQuery('emoji recent cat'), { active: true, query: 'cat', scope: 'recent' }, 'search can be narrowed within recents');
assert.deepStrictEqual(api.parseQuery('emoji heart'), { active: true, query: 'heart', scope: 'all' }, 'ordinary picker search keeps the all-catalog scope');
assert.strictEqual(api.parseQuery('something else').active, false, 'unrelated action terms are not intercepted');

let data = api.emptyData();
data = api.toggleFavorite(data, '❤️');
data = api.toggleFavorite(data, '🐱');
data = api.recordUsage(data, '🚀', 100);
data = api.recordUsage(data, '🐶', 150);
data = api.recordUsage(data, '🐱', 200);
data = api.recordUsage(data, '💡', 300);
const favorites = api.buildResults('', score, 200, data, 'favorites');
assert.deepStrictEqual(favorites.map(x => x.emoji), ['🐱', '❤️'], 'favorite scope contains only favorites and preserves newest-first order');
assert(favorites.every(x => x.isFavorite), 'favorite scope does not leak ordinary results');
const favoriteHeart = api.buildResults('heart', score, 200, data, 'favorites');
assert(favoriteHeart.length > 0 && favoriteHeart.every(x => x.isFavorite), 'query filters within favorites only');
assert(!favoriteHeart.some(x => x.emoji === '🐱'), 'nonmatching favorites are excluded');

const recents = api.buildResults('', score, 200, data, 'recent');
assert.deepStrictEqual(recents.map(x => x.emoji), ['💡', '🐶', '🚀'], 'recent scope is newest-first');
assert(recents.every(x => x.isRecent && !x.isFavorite), 'recent scope contains only recent non-favorites');
const recentSearch = api.buildResults('dog', score, 200, data, 'recent');
assert(recentSearch.some(x => x.emoji === '🐶') && recentSearch.every(x => x.isRecent && !x.isFavorite), 'query filters within recents only');

for (let i = 0; i < 16; i++)
  data = api.recordUsage(data, api.EMOJI_ENTRIES[i].emoji, 1000 + i);
const boundedRecents = api.buildResults('', score, 200, data, 'recent');
assert.strictEqual(boundedRecents.length, api.MAX_RECENT_EMOJIS, 'recent scope is capped at the same 12-item quick-access limit');
assert.strictEqual(boundedRecents[0].emoji, api.EMOJI_ENTRIES[15].emoji, 'recent scope remains most-recent-first');

const all = api.buildResults('', score, 200, data);
assert.strictEqual(all.length, api.EMOJI_ENTRIES.length, 'default all-catalog view is unchanged');
assert.strictEqual(new Set(all.map(x => x.emoji)).size, all.length, 'all-catalog results remain unique');
assert(api.emptyStateMessage('favorites').includes('избранном'), 'favorites empty state is specific');
assert(api.emptyStateMessage('recent').includes('Недавних'), 'recent empty state is specific');
assert(api.emptyStateMessage('all').includes('не найдены'), 'normal search keeps the generic empty state');
console.log('Emoji view parsing, scoped search, favorite/recent filtering, 12-item limit and empty states: OK');
JS

python3 - "$LAUNCHER" <<'PY'
from pathlib import Path
import sys
source = Path(sys.argv[1]).read_text()
assert 'emojiQuery.scope' in source, 'parsed view scope must be passed to emoji result builder'
assert 'LauncherEmojiPicker.emptyStateMessage(' in source, 'view-specific empty state must be shown'
assert 'LauncherEmojiPicker.parseQuery(searchField.text.replace(/^\\s*>\\s*/, "")).query' in source, 'highlighting must ignore scope command token'
print('Launcher QML scope integration, empty state and query highlighting: OK')
PY

echo 'Launcher emoji views: OK'
