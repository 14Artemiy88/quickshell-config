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
const api = vm.runInThisContext(source + '\n({ parseQuery, buildResults, EMOJI_ENTRIES })');

assert.strictEqual(api.parseQuery('emoji').active, true, 'bare emoji prefix opens picker');
assert.strictEqual(api.parseQuery('emoji smile').query, 'smile', 'English search phrase is parsed');
assert.strictEqual(api.parseQuery('эмодзи сердце').query, 'сердце', 'Russian search phrase is parsed');
assert.strictEqual(api.parseQuery('smile').active, false, 'normal action queries are not intercepted');
assert.strictEqual(api.parseQuery('emojiCustom').active, false, 'prefix requires a token boundary');
assert(api.EMOJI_ENTRIES.length >= 100, 'offline catalog must have a useful breadth');

const score = (text, query) => {
  text = String(text).toLowerCase();
  query = String(query).toLowerCase();
  if (!query) return 0;
  if (text === query) return 10000;
  if (text.startsWith(query)) return 9000 - text.length;
  if (text.includes(query)) return 8000 - text.indexOf(query);
  let pos = 0;
  let scoreValue = 0;
  for (const ch of query) {
    const at = text.indexOf(ch, pos);
    if (at < 0) return -1;
    scoreValue += 100 - at;
    pos = at + 1;
  }
  return scoreValue;
};

const all = api.buildResults('', score, 200);
assert.strictEqual(all.length, api.EMOJI_ENTRIES.length, 'bare picker shows the complete offline catalog');
assert(all.every(item => item.kind === 'emoji' && item.emoji && item.name && item.category), 'each result is copy-ready and labeled');

const smile = api.buildResults('smile', score, 200);
assert(smile.length > 0 && smile.some(item => item.emoji === '😀' || item.emoji === '😊'), 'English smile search finds common smiling faces');
const cat = api.buildResults('кошка', score, 200);
assert(cat.some(item => item.emoji === '🐱'), 'Russian aliases find the cat emoji');
const heart = api.buildResults('сердце', score, 200);
assert(heart.some(item => item.emoji === '❤️'), 'Russian aliases find the red heart');
assert.strictEqual(api.buildResults('qzxv-no-match', score, 200).length, 0, 'non-matching query produces no results');
assert.strictEqual(api.buildResults('', score, 3).length, 3, 'result limit is respected');
console.log(`Emoji catalog and search: ${api.EMOJI_ENTRIES.length} entries, parsing, English/Russian matching, result limits: OK`);
JS

python3 - "$LAUNCHER" "$MODULE" <<'PY'
from pathlib import Path
import sys
launcher = Path(sys.argv[1]).read_text()
module = Path(sys.argv[2]).read_text()
assert 'import "../../js/launcher/LauncherEmojiPicker.js" as LauncherEmojiPicker' in launcher
assert 'LauncherEmojiPicker.parseQuery(normalizedQuery)' in launcher
assert 'LauncherEmojiPicker.buildResults(' in launcher
assert 'function appsResultName(itemData, entry)' in launcher and 'case "emoji": return String(itemData.name || "")' in launcher
assert 'case "emoji":' in launcher and 'String(itemData.category || "Эмодзи")' in launcher
assert 'if (result.kind === "emoji")\n            root.copyLauncherEmoji(result.emoji)' in launcher
assert 'function copyLauncherEmoji(value)' in launcher
assert 'kind: "emojiPickerAction"' in launcher and 'searchField.text = ">emoji"' in launcher
assert 'wl-copy' in launcher and 'launcher-emoji-copy' in launcher
assert 'kind: "emoji"' in module
assert 'emoji|emojis|эмодзи|смайлы' in module
print('Launcher >emoji command, app-list rendering, activation and wl-copy integration: OK')
PY

echo 'Launcher emoji picker: OK'
