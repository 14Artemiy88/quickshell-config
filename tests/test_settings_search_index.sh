#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SEARCH="$ROOT/js/settings/SettingsSearch.js"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

sed '1{/^\.pragma library$/d;}' "$SEARCH" > "$TMP/search.js"
cat >> "$TMP/search.js" <<'JS'
module.exports = { normalize, humanizeKey, keyTerms, search };
JS
node - "$TMP/search.js" <<'JS'
const assert = require('assert');
const Search = require(process.argv[2]);

assert.strictEqual(Search.normalize('Wi‑Fi / Ёлка'), 'wi fi елка');
assert(Search.keyTerms('backgroundBlurRadius').includes('блюр'));
assert(Search.keyTerms('networkSpacing').includes('wifi'));
assert(Search.keyTerms('animationDuration').includes('анимация'));
assert.strictEqual(Search.humanizeKey('networkRightPadding'), 'Network Right Padding');

const entries = [
  { id: 'network/update', label: 'Интервал обновления данных', searchText: 'Интервал обновления данных Сеть systemMonitorInterval network обновление частота', keyTerms: 'systemMonitorInterval' },
  { id: 'settings/blur', label: 'Размытие фона', searchText: 'Размытие фона Окно настроек backgroundBlurRadius blur блюр размытие фон', keyTerms: 'backgroundBlurRadius' },
  { id: 'network/show', label: 'Показывать Networks всегда', searchText: 'Показывать Networks всегда Сеть network сеть интернет wi fi wifi', keyTerms: 'network' }
];

assert.deepStrictEqual(Search.search(entries, 'интервал обновления', 7).map(x => x.id), ['network/update']);
assert.deepStrictEqual(Search.search(entries, 'блюр', 7).map(x => x.id), ['settings/blur']);
assert.deepStrictEqual(Search.search(entries, 'wifi', 7).map(x => x.id), ['network/show']);
assert.strictEqual(Search.search(entries, 'нет такого параметра', 7).length, 0);
assert.strictEqual(Search.search(entries, 'сеть', 1).length, 1);
console.log('Settings search normalization, aliases, multi-token matching, ranking and limit: OK');
JS
