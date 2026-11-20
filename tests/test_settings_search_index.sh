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
  { id: 'network/update', label: 'Интервал обновления данных', navigationGroupLabel: 'Модули', pageLabel: 'Сеть', searchText: 'Интервал обновления данных Модули Сеть systemMonitorInterval network обновление частота', keyTerms: 'systemMonitorInterval' },
  { id: 'settings/blur', label: 'Размытие фона', navigationGroupLabel: 'Внешний вид', pageLabel: 'Окно настроек', searchText: 'Размытие фона Внешний вид Окно настроек backgroundBlurRadius blur блюр размытие фон', keyTerms: 'backgroundBlurRadius' },
  { id: 'network/show', label: 'Показывать Networks всегда', searchText: 'Показывать Networks всегда Сеть network сеть интернет wi fi wifi', keyTerms: 'network' }
];

assert.deepStrictEqual(Search.search(entries, 'интервал обновления', 7).map(x => x.id), ['network/update']);
assert.deepStrictEqual(Search.search(entries, 'блюр', 7).map(x => x.id), ['settings/blur']);
assert.deepStrictEqual(Search.search(entries, 'wifi', 7).map(x => x.id), ['network/show']);
assert.deepStrictEqual(Search.search(entries, 'модули сеть', 7).map(x => x.id), ['network/update']);
assert.deepStrictEqual(Search.search(entries, 'внешний вид окно настроек', 7).map(x => x.id), ['settings/blur']);
assert.strictEqual(Search.search(entries, 'нет такого параметра', 7).length, 0);
assert.strictEqual(Search.search(entries, 'сеть', 1).length, 1);

// A short module name must prioritize controls on that module's own page,
// while still retaining module-placement controls lower in the result list.
const weatherEntries = [
  { id: 'modules/weather-enabled', label: 'Погода', pageId: 'modules', pageLabel: 'Модули', searchText: 'Погода Включение модулей modules weather enabled', keyTerms: 'weather погода' },
  ...['X', 'Y', 'Ширина', 'Высота'].map(axis => ({
    id: `modules/weather-${axis}`,
    label: `Погода · ${axis}`,
    pageId: 'modules',
    pageLabel: 'Модули',
    searchText: `Погода ${axis} Модули modules weather geometry`,
    keyTerms: 'weather погода'
  })),
  { id: 'weather/now-interval', label: 'Погода сейчас (мин)', pageId: 'weather', pageLabel: 'Погода', searchText: 'Погода сейчас интервал Модули weather weatherNowIntervalMinutes', keyTerms: 'weather погода температура прогноз' },
  { id: 'weather/hourly-interval', label: 'Погода по часам (мин)', pageId: 'weather', pageLabel: 'Погода', searchText: 'Погода по часам интервал weather weatherHourlyIntervalMinutes', keyTerms: 'weather погода температура прогноз' },
  { id: 'weather/daily-interval', label: 'Погода по дням (мин)', pageId: 'weather', pageLabel: 'Погода', searchText: 'Погода по дням интервал weather weatherDailyIntervalMinutes', keyTerms: 'weather погода температура прогноз' },
  { id: 'weather/temp-width', label: 'Левый · температура', pageId: 'weather', pageLabel: 'Погода', searchText: 'Левый температура Погода weatherTempColumnWidth', keyTerms: 'weather погода температура прогноз' },
  { id: 'weather/wind-width', label: 'Правый · ветер', pageId: 'weather', pageLabel: 'Погода', searchText: 'Правый ветер Погода weatherWindColumnWidth', keyTerms: 'weather погода температура прогноз' },
  { id: 'weather/icon-size', label: 'Размер иконки', pageId: 'weather', pageLabel: 'Погода', searchText: 'Размер иконки Погода weatherIconSize', keyTerms: 'weather погода температура прогноз' }
];
const weatherResults = Search.search(weatherEntries, 'погода', 40);
assert(weatherResults.some(x => x.id === 'weather/now-interval'), 'weather page interval setting is searchable');
assert(weatherResults.some(x => x.id === 'weather/temp-width'), 'weather page generic-label setting is searchable');
assert(weatherResults.findIndex(x => x.id === 'weather/now-interval') < weatherResults.findIndex(x => x.id === 'modules/weather-X'), 'weather page settings rank above weather module geometry');
assert(weatherResults.findIndex(x => x.id === 'weather/temp-width') < weatherResults.findIndex(x => x.id === 'modules/weather-X'), 'all weather page settings receive page-context ranking');
assert(weatherResults.some(x => x.id === 'modules/weather-enabled'), 'module enable toggle remains searchable');
assert(weatherResults.length > 7, 'search can return more than seven matches');
console.log('Settings search normalization, aliases, page-context ranking, module settings coverage, multi-token matching and expanded result limit: OK');
JS
