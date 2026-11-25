#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONTROLLER="$ROOT/components/settings/SettingsSearchController.qml"
fail() { echo "Settings search breadcrumbs: FAIL: $*" >&2; exit 1; }

for contract in \
    'function settingsSearchBreadcrumb(entry)' \
    'navigationPath: root.settingsSearchBreadcrumb({' \
    'current.settingsSearchMatchHint = (breadcrumb.length > 0 ? "Путь: " + breadcrumb' \
    'lines.push("• " + (breadcrumb || match.label)' \
    'var ancestorHint = "• " + (breadcrumb || entry.label)'; do
    grep -Fq "$contract" "$CONTROLLER" || fail "missing breadcrumb contract: $contract"
done

grep -Fq 'root.host.settingsSearchNavigationGroupMatchHint(modelData.id)' "$ROOT/components/settings/SettingsNavigation.qml" \
    || fail 'navigation group search tooltip is no longer connected'
grep -Fq 'root.host.settingsSearchPageMatchHint(parent.modelData.id)' "$ROOT/components/settings/SettingsNavigation.qml" \
    || fail 'page search tooltip is no longer connected'
grep -Fq 'settingsSearchSubTabMatchHint(root.host.currentPageId, index)' "$ROOT/components/settings/SettingsPageHost.qml" \
    || fail 'subtab search tooltip is no longer connected'

node - "$CONTROLLER" <<'NODE'
const assert = require('assert');
const fs = require('fs');
const vm = require('vm');
const source = fs.readFileSync(process.argv[2], 'utf8');

function extractFunction(name) {
  const start = source.indexOf(`    function ${name}(`);
  assert(start >= 0, `${name} exists`);
  const open = source.indexOf('{', start);
  assert(open >= 0, `${name} body exists`);
  let depth = 0, state = 'code', escaped = false;
  for (let i = open; i < source.length; i++) {
    const c = source[i], n = source[i + 1];
    if (state === 'line') { if (c === '\n') state = 'code'; continue; }
    if (state === 'block') { if (c === '*' && n === '/') { state = 'code'; i++; } continue; }
    if (state === 'single' || state === 'double' || state === 'template') {
      if (escaped) { escaped = false; continue; }
      if (c === '\\') { escaped = true; continue; }
      if ((state === 'single' && c === "'") || (state === 'double' && c === '"') || (state === 'template' && c === '`')) state = 'code';
      continue;
    }
    if (c === '/' && n === '/') { state = 'line'; i++; continue; }
    if (c === '/' && n === '*') { state = 'block'; i++; continue; }
    if (c === "'") { state = 'single'; continue; }
    if (c === '"') { state = 'double'; continue; }
    if (c === '`') { state = 'template'; continue; }
    if (c === '{') depth++;
    if (c === '}' && --depth === 0) return source.slice(start, i + 1);
  }
  throw new Error(`${name} body is unclosed`);
}

const breadcrumbFn = vm.runInNewContext(`(${extractFunction('settingsSearchBreadcrumb')})`);
assert.strictEqual(
  breadcrumbFn({ navigationGroupLabel: 'Модули', pageLabel: 'Погода', subTabLabel: 'Анимация', group: 'Интервал обновления', label: 'Продолжительность' }),
  'Модули › Погода › Анимация › Интервал обновления › Продолжительность',
  'full breadcrumb contains frame, page, subtab, section and setting'
);
assert.strictEqual(
  breadcrumbFn({ navigationGroupLabel: 'Общие', pageLabel: 'Общие', subTabLabel: '', group: '', label: 'Масштаб интерфейса' }),
  'Общие › Масштаб интерфейса',
  'duplicate adjacent group/page label is collapsed and empty segments are skipped'
);
assert.strictEqual(breadcrumbFn(null), '', 'missing result has no breadcrumb');

const matchHintFn = vm.runInNewContext(`(${extractFunction('settingsSearchMatchesHint')})`, {
  root: {
    settingsSearchQuery: 'температура',
    settingsSearchResults: [{
      label: 'Температура',
      navigationPath: 'Модули › Погода › Сейчас › Основные › Температура'
    }],
    settingsSearchBreadcrumb: breadcrumbFn
  },
  SettingsSearch: { explainMatch: () => 'совпадение по названию' }
});
const hint = matchHintFn(() => true);
assert(hint.includes('Модули › Погода › Сейчас › Основные › Температура'), 'ancestor result hint includes full breadcrumb');
assert(hint.includes('совпадение по названию'), 'breadcrumb does not replace match explanation');

const target = { settingsSearchHighlighted: false, settingsSearchCurrentMatch: false, settingsSearchMatchHint: '', parent: null };
const section = { settingsSearchHighlighted: false, settingsSearchCurrentMatch: false, settingsSearchMatchHint: '', parent: null };
const pageRoot = { settingsSearchHighlighted: false, settingsSearchCurrentMatch: false, settingsSearchMatchHint: '', parent: null };
target.parent = section; section.parent = pageRoot;
const entry = {
  id: 'weather-temperature', label: 'Температура',
  navigationPath: 'Модули › Погода › Сейчас › Основные › Температура',
  target, pageRoot
};
const applyFn = vm.runInNewContext(`(${extractFunction('applySettingsSearchHighlights')})`, {
  root: {
    settingsSearchIndex: [entry], settingsSearchResults: [entry],
    settingsSearchQuery: 'температура', settingsSearchActiveMatchId: 'weather-temperature',
    clearSettingsSearchHighlights: () => {},
    settingsSearchBreadcrumb: breadcrumbFn
  },
  SettingsSearch: { explainMatch: () => 'совпадение по названию' }
});
applyFn();
assert(target.settingsSearchMatchHint.includes('Путь: Модули › Погода › Сейчас › Основные › Температура'),
  'matched control tooltip includes explicit breadcrumb');
assert(target.settingsSearchMatchHint.includes('Совпадение: совпадение по названию'),
  'matched control tooltip retains semantic match explanation');
assert(section.settingsSearchMatchHint.includes('Модули › Погода › Сейчас › Основные › Температура'),
  'ancestor hint carries the same breadcrumb');
console.log('Breadcrumb generation, duplicate cleanup, match explanation and control/ancestor hints: OK');
NODE

echo 'settings search breadcrumbs: OK'
