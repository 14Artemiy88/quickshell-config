#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REGISTRY="$ROOT/js/settings/SettingsPageRegistry.js"
SEARCH="$ROOT/js/settings/SettingsSearch.js"
CONTROLLER="$ROOT/components/settings/SettingsSearchController.qml"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

sed '1{/^\.pragma library$/d;}' "$REGISTRY" > "$TMP/registry.js"
sed '1{/^\.pragma library$/d;}' "$SEARCH" > "$TMP/search.js"
cat >> "$TMP/registry.js" <<'JS'
module.exports = { pageMetadataCatalog, pageMetadataForId, subTabMetadataForPageId };
JS
cat >> "$TMP/search.js" <<'JS'
module.exports = { search, normalize, explainMatch };
JS

node - "$TMP/registry.js" "$TMP/search.js" "$CONTROLLER" <<'JS'
const assert = require('assert');
const fs = require('fs');
const Registry = require(process.argv[2]);
const Search = require(process.argv[3]);
const controller = fs.readFileSync(process.argv[4], 'utf8');
const pages = Registry.pageMetadataCatalog();
assert.strictEqual(pages.length, 26, 'all pages participate in synonym search');

const entries = [];
let subtabCount = 0;
let keywordPageCount = 0;
for (const page of pages) {
  assert.ok(page.keywords.length >= 3, `${page.id} has useful page-level aliases`);
  keywordPageCount += page.keywords.length;
  const pageKeywords = page.keywords.join(' ');
  const subtabs = page.subTabs || [];
  if (subtabs.length === 0) {
    entries.push({
      id: `${page.id}/page`, label: page.defaultLabel, pageId: page.id,
      pageLabel: page.defaultLabel, pageKeywords,
      keywords: pageKeywords, keyTerms: pageKeywords,
      searchText: [page.defaultLabel, page.id, pageKeywords].join(' ')
    });
  }
  for (const subtab of subtabs) {
    assert.ok(Array.isArray(subtab.keywords), `${subtab.id} exposes a keyword list`);
    assert.ok(subtab.keywords.length >= 2, `${subtab.id} has at least two targeted aliases`);
    const aliases = subtab.keywords.join(' ');
    entries.push({
      id: subtab.id, label: subtab.label, pageId: page.id,
      pageLabel: page.defaultLabel, pageKeywords,
      subTabLabel: subtab.label, keywords: [pageKeywords, aliases].join(' '),
      keyTerms: [pageKeywords, aliases].join(' '),
      searchText: [page.defaultLabel, page.id, pageKeywords, subtab.label, aliases].join(' ')
    });
    subtabCount++;
  }
}
assert.strictEqual(subtabCount, 70, 'all existing subtabs expose targeted synonyms');
assert.ok(keywordPageCount >= 90, 'page synonym catalogue has broad coverage');

function ids(query) { return Search.search(entries, query, 50).map(item => item.id); }
assert(ids('оперативка').some(id => id.startsWith('cpuRam.')), 'everyday RAM wording finds CPU/RAM settings');
assert(ids('озу').some(id => id.startsWith('cpuRam.')), 'common OZU abbreviation finds CPU/RAM settings');
assert(ids('скорость сети').some(id => id.startsWith('network.')), 'network user wording finds Network settings');
assert(ids('wifi ethernet').some(id => id.startsWith('network.')), 'wireless and wired network terms find Network settings');
assert(ids('музыкальный плеер').some(id => id.startsWith('player.')), 'media player synonym finds Player settings');
assert(ids('визуализатор').some(id => id.startsWith('cava.')), 'audio visualizer synonym finds CAVA settings');
assert(ids('всплывающие сообщения').some(id => id.startsWith('notifications.')), 'popup synonym finds Notifications settings');
const playerTabs = Registry.pageMetadataForId('player').subTabs;
assert(ids('время до конца').includes(playerTabs.find(tab => tab.label === 'Оставшееся время').id), 'specific subtab alias finds remaining-time section');
const osdTabs = Registry.pageMetadataForId('osd').subTabs;
assert(ids('экранный индикатор громкости').includes(osdTabs.find(tab => tab.label === 'Громкость').id), 'volume OSD synonym opens the dedicated OSD volume subtab');
assert(ids('смена трека osd').includes(osdTabs.find(tab => tab.label === 'Плеер').id), 'media OSD synonym opens the dedicated OSD player subtab');
assert(ids('индикатор dnd').includes(osdTabs.find(tab => tab.label === 'Не беспокоить').id), 'DND OSD synonym opens its dedicated subtab');
const cpuTabs = Registry.pageMetadataForId('cpuRam').subTabs;
assert(ids('топ процессов').includes(cpuTabs.find(tab => tab.label === 'Top Apps').id), 'specific Top Apps alias finds its subsection');
assert(ids('полоса воспроизведения').includes(playerTabs.find(tab => tab.label === 'Прогресс').id), 'specific progress alias finds Player progress section');
assert.strictEqual(ids('совершенно несуществующая настройка').length, 0, 'unknown terms do not generate false matches');

const cpu = entries.find(item => item.id.startsWith('cpuRam.'));
assert(Search.explainMatch(cpu, 'оперативка').includes('оперативка'), 'match explanation identifies the alias that matched');
assert(controller.includes('pageKeywords: pageKeywords'), 'search entries retain page-level aliases for ranking');
assert(controller.includes('keyTerms, keywords].join(" ")'), 'page and subtab aliases participate in search scoring');
console.log(`Settings search synonyms: ${pages.length} pages, ${subtabCount} subtabs, ${keywordPageCount} page aliases and targeted Russian/English queries: OK`);
JS

echo 'settings search synonyms: OK'
